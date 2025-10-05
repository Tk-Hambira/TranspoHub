#!/bin/bash
docker exec -it $(docker ps -qf "ancestor=wurstmeister/kafka:2.13-2.8.0") \
kafka-topics.sh --create --topic passenger_registered --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1

docker exec -it $(docker ps -qf "ancestor=wurstmeister/kafka:2.13-2.8.0") \
kafka-topics.sh --create --topic ticket_created --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1

docker exec -it $(docker ps -qf "ancestor=wurstmeister/kafka:2.13-2.8.0") \
kafka-topics.sh --create --topic payment_processed --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
