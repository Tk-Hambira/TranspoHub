#!/bin/bash

# Kafka Topics Initialization Script
# This script creates all required Kafka topics for the Smart Public Transport Ticketing System

echo "Waiting for Kafka to be ready..."
sleep 30

echo "Creating Kafka topics..."

# Create ticket.requests topic
kafka-topics --create \
  --bootstrap-server kafka:29092 \
  --topic ticket.requests \
  --partitions 3 \
  --replication-factor 1 \
  --config retention.ms=604800000 \
  --config cleanup.policy=delete

# Create payments.processed topic
kafka-topics --create \
  --bootstrap-server kafka:29092 \
  --topic payments.processed \
  --partitions 3 \
  --replication-factor 1 \
  --config retention.ms=2592000000 \
  --config cleanup.policy=delete

# Create schedule.updates topic
kafka-topics --create \
  --bootstrap-server kafka:29092 \
  --topic schedule.updates \
  --partitions 2 \
  --replication-factor 1 \
  --config retention.ms=86400000 \
  --config cleanup.policy=delete

# Create notifications.send topic
kafka-topics --create \
  --bootstrap-server kafka:29092 \
  --topic notifications.send \
  --partitions 3 \
  --replication-factor 1 \
  --config retention.ms=259200000 \
  --config cleanup.policy=delete

# Create tickets.validated topic
kafka-topics --create \
  --bootstrap-server kafka:29092 \
  --topic tickets.validated \
  --partitions 3 \
  --replication-factor 1 \
  --config retention.ms=2592000000 \
  --config cleanup.policy=delete

# Create service.disruptions topic
kafka-topics --create \
  --bootstrap-server kafka:29092 \
  --topic service.disruptions \
  --partitions 2 \
  --replication-factor 1 \
  --config retention.ms=604800000 \
  --config cleanup.policy=delete

# Create passenger.events topic
kafka-topics --create \
  --bootstrap-server kafka:29092 \
  --topic passenger.events \
  --partitions 2 \
  --replication-factor 1 \
  --config retention.ms=2592000000 \
  --config cleanup.policy=delete

# Create admin.events topic
kafka-topics --create \
  --bootstrap-server kafka:29092 \
  --topic admin.events \
  --partitions 2 \
  --replication-factor 1 \
  --config retention.ms=2592000000 \
  --config cleanup.policy=delete

echo "Listing created topics..."
kafka-topics --list --bootstrap-server kafka:29092

echo "Kafka topics initialization completed!"
