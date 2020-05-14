# Helidon Sock Shop 

This project is an implementation of the microservices based application
using [Helidon Microservices Framework](https://helidon.io/).

The application is an online store that sells, well, socks, and is based
on the canonical [SockShop Microservices Demo](https://microservices-demo.github.io)
originally written and published under Apache 2.0 license by [Weaveworks](https://go.weave.works/socks).

You can see a working demo of the original application [here](http://socks.weave.works/).

This demo still uses the original front end implementation provided by Weaveworks,
but all back end services have been re-implemented from scratch to use Helidon MP 
and showcase its features and best practices.

## Architecture

The application consists of a Node.js-based front end (the same one that is used in the original
WeaveSocks demo application) and 6 back end services (rewritten from the ground up on top of
Helidon, implementing the API that the legacy `front-end` service expects).

![Architecture Diagram](./doc/images/architecture.png)

- **[Product Catalog](https://github.com/helidon-sock-shop/catalog)**, which provides 
REST API that allows you to search product catalog and retrieve individual product details;

- **[Shopping Cart](https://github.com/helidon-sock-shop/carts)**, which provides 
REST API that allows you to manage customers' shopping carts;

- **[Orders](https://github.com/helidon-sock-shop/orders)**, which provides REST API 
that allows customers to place orders;

- **[Payment](https://github.com/helidon-sock-shop/payment)**, which provides REST API 
that allows you to process payments;

- **[Shipping](https://github.com/helidon-sock-shop/shipping)**, which provides REST API 
that allows you to ship orders and track shipments;

- **[Users](https://github.com/helidon-sock-shop/users)**, which provides REST API 
that allows you to manage customer information and provides registration and 
authentication functionality for the customers.

Each service has a _core_ module, which is where most of the code for the service is
(domain model, JAX-RS resources, etc.), and which also provides a basic in-memory
implementation of the data store that is useful for testing.

Most services also have one or more data store-specific modules, which build on the
_core_ module and demonstrate integrations of popular data stores with Helidon 
(MySQL, Mongo, Redis, etc.)
 
You can find more details for each service within documentation pages for individual
services, which can be accessed using the links above.

## Project Structure

Each back end service described above has its own Github repo, so it can be versioned
and released independently from other services. 

In addition to that, there is also a main 
[Sock Shop](https://github.com/helidon-sock-shop/sockshop) repository (the one you are 
currently in), which contains Kubernetes deployment files for the whole application, 
top-level POM file which allows you to easily build the whole project and import it 
into your favorite IDE, and a _bash_ script that makes it easy to checkout and update 
all project repositories at once.

## Quick Start

The easiest way to try the demo is to use [provided Docker images](https://hub.docker.com/orgs/helidonsockshop/repositories)
and Kubernetes deployment scripts from this repo. 

Kubernetes scripts depend on Kustomize, so make sure that you have a newer version of `kubectl`
that supports it (at least 1.14 or above). 

If you do, you can simply run the following command from the `sockshop` directory
and replace `BACKEND` with one of the following indicating the type of back-end you want to deploy.

* core - Core back-end
* mongo - MongoDB back-end
* mysql - MySQL database back-end 
* redis - Redis back-end

```bash
$ kubectl apply -k k8s/BACKEND 
``` 

e.g.

```bash
$ kubectl apply -k k8s/core 
```

from the top-level directory, and this will merge all the files under the specified 
directory and create all Kubernetes resources defined by them, such as deployment
and service for each microservice.

Port-forward the front-end UI using the following

Mac/Linux

```bash
$ export FRONT_END_POD=$(kubectl get pods -o jsonpath='{.items[?(@.metadata.labels.app == "front-end")].metadata.name}')
$ kubectl port-forward $FRONT_END_POD 8079:8079
```

Windows:
```command
kubectl get pods -o jsonpath='{.items[?(@.metadata.labels.app == "front-end")].metadata.name}' > pod.txt
SET /P FRONT_END_POD=<pod.txt
kubectl port-forward %FRONT_END_POD% 8079:8079
```

> Note: If you have installed into a namespace then add the `--namespace` option to all kubectl commands in these instructions.

You should be able to access the home page for the application by pointing your browser to http://localhost:8079/.

You should then be able to browse product catalog, add products to shopping cart, log in as an 
existing test user (username: `user`, password: `pass`) or register as a new user, place an order,
browse order history, etc.

Once you are finished, you can clean up the environment by executing

```bash
$ kubectl delete -k k8s/core 
```   

## Extending the Deployment

You can extend the deployment in a number of ways if you are using a remote Kuberenetes cluster.

### Pre-Requisites

You must download `envsubst` for your platform from [https://github.com/a8m/envsubst](https://github.com/a8m/envsubst). 

### Expose via a Load Balancer                               

1. Create the Load Balancer

    ```bash
    $ kubectl apply -f k8s/optional/ingress-controller.yaml 
    
    $ kubectl get services -n ingress-nginx
    NAME            TYPE           CLUSTER-IP       EXTERNAL-IP       PORT(S)                      AGE
    ingress-nginx   LoadBalancer   AAA.BBB.CCC.DDD   WWW.XXX.YYY.ZZZ  80:31475/TCP,443:30578/TCP   17s    
    ```      

    Once you have been assigned an external IP address, continue to the next step.              

1. Setup Domains

    You must have access to a top level domain for which you can create sub-domains to 
    allow access to the application via a Load Balancer (LB).

    For example if your top level domain is `mycompany.com` then you
    should create a single wildcard DNS entry `*.sockshop.mycompany.com` to 
    point to your external LB IP address.
    
1. Create the ingress

    Each time you use a different back-end you will need to create a new ingress.

    In your terminal, export (or SET for Windows) your top level domain
    and the backend you are using. 
    
    For example for domain `sockshop.mycompany.com` and `memory` backend, use the following 
    
    ```bash
    $ export SOCKSHOP_DOMAIN=sockshop.mycompany.com
    $ export SOCKSHOP_BACKEND=memory                            
    
    $ envsubst -i k8s/optional/ingress.yaml| kubectl apply -f -
    
    $ kubectl get ingress  
    
    NAME               HOSTS                                                                                         ADDRESS           PORTS   AGE
    mp-ingress         mp.memory.mycompany.com                                                                       XXX.XXX.XXX.XXX   80      12d
    sockshop-ingress   memory.sockshop.mycompany.com,jaeger.memory.sockshop.mycompany.com,api.memory.mycompany.com   XXX.XXX.XXX.XXX   80      12d
    ```         

1. Access the application

    Access the application via the endpoint http://memory.sockshop.mycompany.com/ 

1. Cleanup the ingress

    To cleanup the ingress for your deployment, issue the following ensuring you have the same
    environment variables set from when you created the ingress. 

    ```bash 
    $ export SOCKSHOP_DOMAIN=sockshop.mycompany.com  
    $ export SOCKSHOP_BACKEND=memory                             
    
    $ envsubst -i k8s/optional/ingress.yaml| kubectl delete -f -
    ``` 
    
1. Remove the LB (Optional)
    
    If you wish to remove your LB, issue the following
    
    ```bash
    $ kubectl delete -f k8s/optional/ingress-controller.yaml
    ```

### Configure Jaegar

```bash
$ kubectl create -f k8s/optional/jaeger-operator.yaml 

$ kubectl create -f k8s/optional/jaegar.yaml
```                                         

Access the application via the endpoint http://jaegar.memory.sockshop.mycompany.com/ 


### Cleanup the Extensions

Once you are finished, you can clean up the environment by executing

```bash
$ kubectl delete -f k8s/optional/ingress-service.yanl

$ kubectl delete -f k8s/optional/jaeger-operator.yaml 

$ kubectl delete -f k8s/optional/jaegar.yaml

$ kubectl delete namespace observability
```   


## Development
 
If you want to modify the demo, you will need to check out the code for the project, build it 
locally, and (optionally) push new Docker images to the repository of your choice.
 
### Checking Out the Project

The easiest way to checkout the source code for all the services is to run the provided 
`update.sh` script:

```bash
$ mkdir helidon-sock-shop
$ cd helidon-sock-shop
$ bash <(curl -s https://raw.githubusercontent.com/helidon-sock-shop/master/update.sh)
```

Once you have the code locally, you can update it to the latest version by running the 
same script locally:

```bash
$ cd helidon-sock-shop
$ . update.sh
```

>**Note:** Make sure that you run the update script from the same top-level directory 
>that you used to checkout all the services into or it will fail.

### Building the Code

You can build individual services by running `mvn clean install` within top-level directory
for each service, but if you want to build the whole project at once, there is an easier
way: simply run `mvn clean install` within the `sockshop` directory.

This will compile the code for each service, run the tests, and install module JARs into
the local Maven repo. 

### Creating Docker Images

Pre-built Docker images are already available on [DockerHub](https://hub.docker.com/orgs/helidon/repositories),
so you can simply run `docker pull` to download them and use locally.

However, if you are making changes to various service implementations and need to re-create
Docker images, you can easily do that in several different ways.

If you only want to build Docker images locally, make sure that you have Docker Daemon
running and execute the following command: 

```bash
$ mvn package -Pdocker -DskipTests
```

You can then tag images any way you want and push them to a Docker repo of your choice 
using standard Docker commands.

On the other hand, if you cannot or do not want to run Docker locally, you can push images
directly to the remote repository:

```bash
$ mvn package -Pdocker -DskipTests -Ddocker.repo=<your_docker_repo> -Djib.goal=build
```

> **Note:** You should replace `<your_docker_repo>` in the command above with the name of the 
> Docker repository that you can push Docker images to.

> **Note:** We use [Jib Maven Plugin](https://github.com/GoogleContainerTools/jib) to create and publish
> Docker images, with a default Jib goal set to `dockerBuild`, in order to create local image.
> Changing the goal to `build` via `jib.goal` system property allows you to push images to a 
> remote repository directly.

### Running Modified Application

Kubernetes deployment scripts in this repository reference Docker images from the default
Docker Hub repository, `helidon/sockshop`. You will not be able to push the images to that repo,
which is why you had to specify `-Ddocker.repo` argument in the command above.

In order to deploy the application that uses your custom Docker images, you will also have to modify
relevant `deployment.yaml` files within `sockshop` repository to use correct names for your
Docker images.

## License

Apache License 2.0
