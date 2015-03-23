---
title: Docker DNS
---

One of the reasons why I like Docker is that it makes development with external
services much easier to do. If you are working with a microservices
architecture it is a regular occurence that you want to work on service A, but
you need access to service B somewhere in service A. Doing that with Docker,
and more specifically [docker-compose][docker-compose], is a cinch. I will not
go into the details in this blog post, but essentialy you define your
`docker-compose.yml` something like this

[docker-compose]: https://github.com/docker/compose

```
serviceb:
    image: username/serviceb

servicea:
    image: username/servicea
    links:
        - serviceb
```

When you execute `docker-compose up servicea` it will automatically start
service B and make the IP of service B available in the service A container via
an environment variable.

A small annoyance I had with this set-up was that whenever I wanted to connect
to service B directly, I needed its IP not in a container but on the host
machine. The default way to get access to its IP is by executing

```
docker inspect --format "{{ .NetworkSettings.IPAddress }}" <container_name>
```

The downside of this approach is that whenever I restart service B, it will get
a new IP address, forcing me to look it up again. And I always forget the exact
syntax for the `format` option, so I have to google it everytime.

Let's fix that!

<!--more-->

Enter [`tonistiigi/dnsdock`][dnsdock]. It is a Docker container that will act
as a local DNS for your Docker containers.

[dnsdock]: https://github.com/tonistiigi/dnsdock

The setup is pretty easy, just run

```
docker run -d -v /var/run/docker.sock:/var/run/docker.sock --name dnsdock -p 172.17.42.1:53:53/udp tonistiigi/dnsdock
```

This will expose your `docker.sock` inside the container so it has access to
all the docker containers.

All you need to do now is add `172.17.42.1` as a DNS server in your OS. On
Ubuntu 14.04 you can do this by adding `nameserver 172.17.42.1` to
`/etc/resolvconf/resolv.conf.d/head` and running `sudo resolvconf -u`.

By default the DNS will respond with the IP of a container on URLs of the form

```
<container-name>.<image-name>.docker
```

You can always override the `image-name` and `container-name` by providing the
environment variables `DNSDOCK_IMAGE` and `DNSDOCK_NAME` to the container. Thus
our `docker-compose.yml` would look like this

```
serviceb:
    image: username/serviceb
    environment:
        - DNSDOCK_NAME=serviceb-1
        - DNSDOCK_IMAGE=serviceb
```

We can now reach our service at `serviceb-1.serviceb.docker`, isn't that handy?
