import std/[locks, os, sets, strformat, strutils]
import mummy, mummy/routers
import piclock

var
  L: Lock
  serverThread: Thread[Server]
  clockThread: Thread[void]
  clients: HashSet[WebSocket]
  data: string

initLock(L)

proc toData(frame: LcdFrame): string =
  var data: seq[string]
  for y in 0..63:
    for x in 0..127:
      if frame[x][y]:
        data.add("1")
      else:
        data.add("0")
  result = data.join()

proc indexHandler(request: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/html"
  let indexFile = open("index.html").readAll()
  request.respond(200, headers, indexFile)

proc upgradeHandler(request: Request) =
  let websocket = request.upgradeToWebSocket()
  {.gcsafe.}:
    withLock L:
      websocket.send(data)

proc websocketHandler(websocket: WebSocket,
                      event: WebSocketEvent,
                      message: Message) =
  case event:
  of OpenEvent:
    echo "Client connected: ", websocket
    {.gcsafe.}:
      withLock L:
        clients.incl(websocket)
  of MessageEvent:
    echo message.kind, ": ", message.data
  of ErrorEvent:
    discard
  of CloseEvent:
    echo "Client disconnected: ", websocket
    {.gcsafe.}:
      withLock L:
        clients.excl(websocket)

proc serverProc(server: Server) =
  let address = "0.0.0.0"
  echo fmt"Serving on http://{address}:8080"
  {.gcsafe.}:
    server.serve(Port(8080), address = address)

proc clockProc =
  while true:
    {.gcsafe.}:
      withLock L:
        data = drawTime().toData()
        for c in clients:
          c.send(data)
    sleep(250)

var router: Router
router.get("/", indexHandler)
router.get("/ws", upgradeHandler)

let server = newServer(router, websocketHandler)

createThread(serverThread, serverProc, server)
createThread(clockThread, clockProc)

joinThread(serverThread)
joinThread(clockThread)
