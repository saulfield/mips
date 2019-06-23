#!/bin/bash

yosys control.v -p "write_json control.json"
netlistsvg -o control.svg control.json