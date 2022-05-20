---
layout: post
title: "Calling Go from Python via gRPC"
tags: grpc go python stream tls
excerpt: "In this post I’ll show you how to make remote procedure calls via gRPC between Python and Go, securing the communication with TLS."
---

A common problem for developers is the invocation of code running in
separate contexts. To give some examples, the developer may connect to
a service to download a file, retrieve the inbox mail, get its feed
and many more. A modern framework to connect services in and across
data centers is [gRPC](https://grpc.io/). In this post I'll show you
how to make **remote procedure calls** via **gRPC** between Python and
Go. I'll also share some tips to provide end-to-end security of data
transmitted.

+ [What is gRPC](#what-is-grpc)
+ [The project](#the-project)
  - [Service interface](#service-interface)
  - [Generating the server and the stub](#generating-the-server-and-the-stub)
  - [Serving single requests](#serving-single-requests)
  - [Implementing a server stream](#implementing-a-server-stream)
+ [Securing communication (multi TLS)](#securing-communication)


## What is gRPC

As mentioned before, gRPC is a high performance remote procedure call
framework. gRPC is based on the idea of defining a service. The
service specifies a set of methods that can be called remotely, along
with their type parameters. The service interface is implemented and
exposed by a server. A client can talk to the server simply by calling
one of the methods defined in the interface.

<div style="margin-right: auto; margin-left: auto; width: 100%; max-width: 600px;">
  <img src="/assets/blog_assets/2022_05_20/client-stub.png" alt="">
</div>
<b>

What makes gRPC special is that the client can invoke the functions
exposed by the server simply by calling them, as if they were locally
defined. Moreover, since the service interface is language agnostic,
there is no need to worry about the interoperability between the
languages used to implement the client or the server (contrary to what
happens with Foreign Function Interfaces FFIs). Indeed, client and
server do not communicate sharing raw memory directly, but with
_messages_. To structure them gRPC relies on [Protocol
Buffers](https://developers.google.com/protocol-buffers/docs/overview),
an open source mechanism for serializing structured data.

## The project

To illustrate how gRPC works I'll use a basic example. Imagine you
have a web mapping platform like Google Maps, you may have some
satellites scanning the Earth and storing the data on a server, and
clients performing some queries to the server to get the view of a
location. For simplicity, assume you already have a 80x32 (width,
height) 2D map of the Earth stored on the server. The goal is to
support queries to get the image associated with the `xy` coordinate
of a location, and also queries to get the view associated with a
broader rectangular area delimited by the `xy` coordinates associated
with its bottom-left and top-right corners. Also, you may want to
encrypt the communication between client and server to counter
eavesdropping and ensure no third-parties are able to perform MITM
attacks (i.e., like replacing the image associated with a coordinate).

In the following sections we'll go through the implementation
step-by-step. The source code is available
[here](https://github.com/dariofad/grpc_py_go_example).

### Service interface

The first step when working with protocol buffers is to define the
structure for the data that will be shared between client and server,
or the _messages_. These structures are defined in a proto file, which
is simply a text file with a `.proto` extension. Each message can be
seen as a struct, and the important thing to understand is that the
_fields_ in each message have fixed type and pre-defined
ordering. Let's see what messages look like in our `satellite.proto`
file.

```
syntax = "proto3";

message Location {
	int32 x = 1;
	int32 y = 2;	
}

message Area {
	Location ll = 1;
	Location ur = 2;	
}

message Image {
	int32 x = 1;
	int32 y = 2;
	bytes img = 3;
}
```

As we can see from the code, the `Location` message uses only **scalar
types**, the `x` and `y` coordinates. To each scalar type, Protocol
buffers enable the serialization (without loss of information) to a
programming language target type (see
[here](https://developers.google.com/protocol-buffers/docs/proto3#scalar)
for the complete reference).  Messages can also be used as fields in
other messages, as can be seen in `Area`. This is called _nested_
messages. With regard to the `Image` message, I opted for using simply
`bytes`.

Now that we have defined the messages, we need to define the
services. This can be done directly in the proto file used for the
definition of messages. In our case we're going to have a single
service `Satellite`. The service is going to expose two RPCs:
`GetImage` to return a single image, and `GetImages` to return
multiple images (for the rectangular area).

```
service Satellite {
	rpc GetImage (Location) returns (Image) {};
	rpc GetImages (Area) returns (stream Image) {};
}
```

`GetImage` is a unary RPC where the client sends a single request to
the server and gets a response back (just like a normal function
call), while `GetImages` is a server streaming RPC, where the client
sends a single request to the server and gets a stream to read a
sequence of messages back.

### Generating the server and the stub

The next step to be performed is the automatic generation of the
client stub and the gRPC server. To do this we first need to install
the `protoc` compiler to serialize the messages (available
[here](https://github.com/protocolbuffers/protobuf/)), the
`protoc-gen-go-grpc` tool to generate the Go bindings to our service
for the server (available
[here](https://pkg.go.dev/google.golang.org/grpc/cmd/protoc-gen-go-grpc#section-readme)),
and `grpcio`, `grpcio-tools`, and `protobuf` packages to generate the
bindings to our service for the Python client (the Makefile in the
project provides a recipe to automatically download and install the
dependencies). It is important to separate in different directories
the code associated with the service interface, the server, and the
client. The structure I'm using for the project is:

```
├── client
│   ├── app.py
├── protos
│   └── satellite.proto
├── server
│   └── server.go
```

To generate the bindings we start from the server. We want to generate
them inside `server/`, in a dedicated package. To do that, we add to
the proto file (immediately after `syntax`) the lines:

```
package satellite;
option go_package = "example.com/satellitepb";
```

and run:

```bash
protoc --go-grpc_out=server/ --go_out=server/ protos/satellite.proto
```

from the command line. Then we generate the bindings for the
client. The Python toolchain requires a slightly different
configuration, in this case we are going to generate the bindings
inside `client/protos/`. To do that we run:

```python -m grpc_tools.protoc -I. --python_out=client --grpc_python_out=client protos/satellite.proto```

As a result of the previous steps you should see the following files
in the project directory:

```
├── client
│   ├── protos
│   │   ├── satellite_pb2_grpc.py
│   │   └── satellite_pb2.py
├── server
│   ├── example.com
│   │   └── satellitepb
│   │       ├── satellite_grpc.pb.go
│   │       └── satellite.pb.go
```

The generation of the service interface for the client and the server
is complete.

### Serving single requests

To serve single requests we first need to spawn a gRPC server on a
dedicated port, then we have to provide an implementation of
the `GetImage` service.

#### Server

In our case, the server stores the map along with two loggers, one to
log information such as incoming requests, and the other to log
errors. Please note that we also need to embed the automatically
generated `satellitepb.UnimplementedSatelliteServer`. This is done to
ensure forward compatible implementations (the inner type is used as a
base class in an OOP language).  At initialization time, we get an
instance of the server and load the map from a template.  We
previously defined the map as a collection of images, each represented
as a sequence of bytes. However, to demonstrate how gRPC works we can
just replace each image by a single character (empty character for the
sea, non empty character for land). Nothing changes from a technical
perspective, but doing so allow us to print the map nicely to console.

```go
var (
	height int = 32
	width  int = 80
)

type Server struct {
	satellitepb.UnimplementedSatelliteServer
	InfoLog                                  *log.Logger
	ErrorLog                                 *log.Logger
	sMap                                     []string
}

func NewServer() *Server {

	s := &Server{}
	s.InfoLog = log.New(os.Stdout, "INFO:\t", log.Lmicroseconds)
	s.ErrorLog = log.New(os.Stdout, "ERROR:\t", log.Lmicroseconds)
	s.sMap = make([]string, height)

	return s
}

func (s *Server) LoadMap(fname string) {
	...
}

func main() {

	// load the example map
	s := NewServer()
	s.LoadMap("map.txt")

	// create a tcp listener
	lis, err := net.Listen("tcp", "0.0.0.0:8000")
	if err != nil {
		log.Fatalf("Cannot listen to 0.0.0.0:8000 %v", err)
	}

	// init the gRPC server
	grpcServer := grpc.NewServer()
	satellitepb.RegisterSatelliteServer(grpcServer, s)

	// serve requests
	log.Println("Server starting...")
	log.Fatal(grpcServer.Serve(lis))
}

```

After loading the map we start a tcp listener on port 8000, and
instantiate the default gRPC server. The default gRPC server has no
service registered and has not started to accept requests yet. The
skeleton of the server is implemented in the `google.golang.org/grpc`
package. We register our `Server` to it using the bindings generated
with `protoc-gen-go-grpc`. After that, we can serve incoming requests
on port 8000. The skeleton implementation of the server provides the
logic to accept incoming connections on the listener `lis`. Each
service request will be handled in a dedicated goroutine, and served
invoking the proper handle.

To effectively serve `GetImage` requests we have to provide an
implementation of the related handle (if you remember we have embedded
in our `Server` struct the type
`satellitepb.UnimplementedSatelliteServer`). The prototype of the
handler is again defined in `satellite_grpc.pb.go`, we just need to
add the body as shown below.

```go
func (s *Server) GetImage(ctx context.Context, loc *satellitepb.Location) (*satellitepb.Image, error) {

	s.InfoLog.Printf("GetImage request (x: %d, y: %d)\n", loc.X, loc.Y)

	isValidCoord := s.CheckLocation(loc)

	if !isValidCoord {
		return nil, status.Errorf(codes.OutOfRange,
			OutOfBoundFmt,
			loc.X,
			loc.Y)
	}

	h := loc.Y
	w := loc.X

	img := &satellitepb.Image{
		Y:   int32(h),
		X:   int32(w),
		Img: []byte{s.sMap[h][w+1]},
	}

	return img, nil
}
```

The fuction receives as arguments a context `ctx` (which can be used
to attach metadata and specify deadlines) and a `Location` message,
and returns an `Image` as defined in the proto interface. Upon
receiving a request, the server writes a record to the log, validates
the coordinate, retrieves an image from the map, and then uses the
proto interface to return it to the caller.

#### Client

The client must be able to open a channel to the server, send requests
using the stub, and wait for the result. The procedure here is
straightforward: 1) we use the `grpc.aio.insecure_channel()` method to
create a channel to the server (specifying host and port), 2)
instantiate the client stub using the bindings `satellite_pb2_grpc.py`
generated with protoc, and 3) send the requests one at a time using the
method `GetImage()` implemented by the auto-generated stub. Since
requests are asynchronous operations, an Event Loop is used to run
until the future (i.e., each request) has completed. The code is shown
below.

```python
server = '0.0.0.0:8000'
proxy = SimpleProxy(server)
locations = {(1,2), (30,25), (50,4), (0,0), (50,16), (10, 1)}
result = proxy.GetRequests(locations)

class SimpleProxy:
    
    def __init__(self, server):

        self.server = server
        
    def GetRequests(self, locations):

        # Get single locations
        print("[*] gRPC single requests:")

        return asyncio.get_event_loop().run_until_complete(self._getRequests(locations))
    
    async def _getRequests(self, locations):

        result = []

        async with grpc.aio.insecure_channel(self.server) as channel:

            # Init the client stub
            stub = protos.satellite_pb2_grpc.SatelliteStub(channel)

            for loc in locations:
                try:
                    response = await self._get_img(stub, loc)
                    result.append((loc[0], loc[1], response.img))
                except grpc.RpcError as e:
                    status_code = e.code()
                    if grpc.StatusCode.OUT_OF_RANGE == status_code:
                        print("Bad request, out of bound location", loc)
                    else:
                        print(e)
        return result
        
    def _get_img(self, stub: protos.satellite_pb2_grpc.SatelliteStub, location):

        loc = protos.satellite_pb2.Location()
        loc.x = location[0]
        loc.y = location[1]
    
        # send the request using the stub
        return stub.GetImage(loc)
```




### Implementing a server stream

#### Server

In the requirements we mentioned the ability to query the server to
get a rectangular area of the map. Consider that, in a real scenario,
maps can grow very large, and we want to avoid the client to block
until a big area is fully downloaded. The idea is then to send to the
client a stream of messages associated with each location in the
requested area, enabling the client app to render each image to the UI
as soon as it is available.

To do that, we need to implement the server's `GetImages()`
interface. Starting from the prototype generated in the
`satellite_grpc.pb.go` file, we create a function as shown below.

```go
func (s *Server) GetImages(area *satellitepb.Area, stream satellitepb.Satellite_GetImagesServer) error {

	s.InfoLog.Printf(
		"GetImages stream request (x: %d, y: %d) -> (x: %d, y: %d)\n",
		area.Ll.X, area.Ll.Y, area.Ur.X, area.Ur.Y)

	/* ...check valid area...*/
	
	for j := int(area.Ur.Y - area.Ll.Y); j > 0; j-- {
		for i := 0; i < int(area.Ur.X-area.Ll.X); i++ {

			w := int(area.Ll.X) + i
			h := int(area.Ll.Y) + j

			img := &satellitepb.Image{
				Y:   int32(h),
				X:   int32(w),
				Img: []byte(s.sMap[h][w : w+1]),
			}

			if err := stream.Send(img); err != nil {
				return err
			}
		}
	}

	return nil
}
```

The key point here is to send multiple messages back to the client
using the `stream.Send()` function. gRPC does not wait until the
message is received by the client. As a result, an untimely stream
closure may result in lost messages.

#### Client

Client side, we need to provide a way to download the map (or part of
it), and simultaneously render it to the console. The simplest way to
do so is perhaps using two processes exchanging memory with a
queue. In the first process we execute a modified version of the proxy
(which is used to query the server), while in the second, we run the
rendering process to update the local map and visualize it to the UI.

```python
queue = Queue()
area = [(0,0), (79,31)] # coordinates of the area to download

def Query(proxy, queue, area):
    proxy.GetStream(queue, area)
    
query = Process(target=Query, args=(proxy, queue, area,))
query.start()

# rendering to console
while True:
	map.Render(...)
```

Compared to the single requests case, we just need to wait until the
server stream is closed, and put each image into the queue as soon as
it is available.

```python
async def _get_imgs(self, queue, stub: protos.satellite_pb2_grpc.SatelliteStub, xy1, xy2):

    ll = protos.satellite_pb2.Location()
    ll.x = xy1[0]
    ll.y = xy1[1]

    ur = protos.satellite_pb2.Location()
    ur.x = xy2[0]
    ur.y = xy2[1]

    area = protos.satellite_pb2.Area()
    area.ll.CopyFrom(ll)
    area.ur.CopyFrom(ur)

    responses = stub.GetImages(area)
    async for response in responses:
        queue.put([response.x, response.y, response.img])

    queue.put(None)
```

Just for the sake of testing, the server implementation in the
repository uses a `SLEEP_TIME` between calls to `stream.Send()` to
simulate the delay introduced by larger images. A fixed sleep time of
1 or 2 ms is should be enough to demonstrate the approach. Larger
sleep times (e.g., >15 ms) can be used to test the cancellation of a
request (i.e., the client can set a deadline for the request to be
served).

We're ready for a demo!

<div style="margin-right: auto; margin-left: auto; width: 100%; ">
  <img src="/assets/blog_assets/2022_05_20/demo.gif" alt="">
</div>
<b>



## Securing communication

In the introduction we mentioned the ability to encrypt the
communication between client and server to counter eavesdropping and
ensure no third-parties are able to perform MITM attacks. Up to now,
no action was taken to fulfill this requirement. To demonstrate that,
we can inspect the network communication using Wireshark.

<div style="margin-right: auto; margin-left: auto; width: 100%; max-width: 850px;">
  <img src="/assets/blog_assets/2022_05_20/no_tls.png" alt="">
</div>
<b>

As you may have noticed from the previous gif, some metadata is
attached to the request performed by the client. Its name is `token`,
and the value '03357-1'. Looking at packet 6 from the trace, it is
clear that the requests and data are sent in plaintext between client
and server, so no confidentiality is ensured. It is even worse the
fact that somebody can impersonate either the client or the server and
replace the data exchanged.

gRPC offers several [ways](https://grpc.io/docs/guides/auth/) to
authenticate and secure communication. In this post we're going to see
how to encrypt all the data and perform mutual authentication for
client and server using TLS. This is somehow the simplest way to do
so. To make it work, we have to start from certificates.

In TLS, certificates are issued by a trusted certificate authority
(simply CA). Since we're simulating everything from scratch we assume
no CA is available, hence we're going to create a valid certificate
for the CA, for the server and for the client using `openssl`. We
start from the CA. Let's run:

```bash
openssl req -x509 -newkey rsa:4096 -days 30 -nodes -keyout certs/ca-key.pem \
		-out certs/ca-cert.pem -subj "/C=/ST=/L=/O=My CA/OU=/CN=/emailAddress="
```

The command creates a new private RSA key and a public x509
certificate for the CA (the `-subj` argument), saving them in pem
format in the `cert` directory. Expiration is set in 30 days. To
inspect their content you can run `openssl rsa -in certs/ca-key.pem
-text` and `openssl x509 -in certs/ca-cert.pem -text`, respectively.

The process for the client and the server is slightly different, we're
still creating the private and public keys using `openssl`, but we
have to simulate the submission of a certificate sign request (CSR) to
the CA for producing a validate certificate. This is how to do that on
behalf of the server (the same applies for the client).

```bash
# Server's keys + CSR
openssl req -newkey rsa:4096 -nodes -keyout certs/server-key.pem -out certs/server-req.pem \
		-subj "/C=/ST=/L=/O=Server/OU=/CN=/emailAddress="
		
# Inspect and verify the CSR
openssl req -text -noout -verify -in certs/server-req.pem

# Sign the CSR with CA's key to generate a valid certificate
openssl x509 -req -in certs/server-req.pem -days 30 -CA certs/ca-cert.pem \
		-CAkey certs/ca-key.pem -CAcreateserial -out certs/server-cert.pem \
		-extfile certs/server-ext.cnf
```

Now that we have generated valid certificates we have to configure the
server and the client to use them to setup the communication
channel. We start from the server. First we create a new valid set of
TLS credentials, then we inject them at gRPC server init time. The new
credentials collect the private key and the public certificate of the
server, as well as the public certificate of the trusted CA. It also
tells the server that the client must be successfully authenticated
for its requests to be served.

```go
func loadTLSCreds() (credentials.TransportCredentials, error) {

	caCert, err := ioutil.ReadFile("../certs/ca-cert.pem")
	if err != nil {
		return nil, err
	}

	certPool := x509.NewCertPool()
	if !certPool.AppendCertsFromPEM(caCert) {
		return nil, fmt.Errorf("failed to add CA's certificate")
	}

	serverCert, err := tls.LoadX509KeyPair("../certs/server-cert.pem", "../certs/server-key.pem")
	if err != nil {
		return nil, err
	}

	cfg := &tls.Config{
		Certificates: []tls.Certificate{serverCert},
		ClientAuth:   tls.RequireAndVerifyClientCert,
		ClientCAs:    certPool,
	}

	return credentials.NewTLS(cfg), nil
}

func main() {

	/* ... */
	
	// load TLS credentials
	tlsCreds, err := loadTLSCreds()
	if err != nil {
		log.Fatalf("Error loading TLS credentials %v", err)
	}

	// init the gRPC server
	grpcServer := grpc.NewServer(grpc.Creds(tlsCreds))

	/* ... */
}
```

Similarly to what we did for the server, we setup the client to use
the certificates. We also update the `_getRequests()` and
`_getStream()` methods to use a secure communication channel.

```python
class SimpleProxy:

    def __init__(self, server):

        self.server = server
        self.ca_cert, self.client_cert, self.client_key = self._readCertificates()
        # setup the new gRPC credentials
        self.grpc_credentials = grpc.ssl_channel_credentials(
            root_certificates=self.ca_cert,
            private_key=self.client_key,
            certificate_chain=self.client_cert)

    def _readCertificates(self):

        with open("./certs/ca-cert.pem", 'rb') as f1:
            caCert = f1.read()

        with open("./certs/client-cert.pem", 'rb') as f2:
            clientCert = f2.read()

        with open("./certs/client-key.pem", 'rb') as f3:
            clientKey = f3.read()
            
        return caCert, clientCert, clientKey
		
    async def _getRequests(self, locations):

        async with grpc.aio.secure_channel(self.server, self.grpc_credentials) as channel:

            # Init the client stub with the secure channel
            stub = protos.satellite_pb2_grpc.SatelliteStub(channel)

            """...call the service..."""		
```

Let's again inspect the network traffic with Wireshark.

<div style="margin-right: auto; margin-left: auto; width: 100%; max-width: 850px;">
  <img src="/assets/blog_assets/2022_05_20/tls.png" alt="">
</div>
<b>

As you can see from the result, client and server perform a TLS
handshake to establish a secure channel, and all application data is
sent encrypted.

The source code is available
[here](https://github.com/dariofad/grpc_py_go_example).

I hope you enjoyed it!
