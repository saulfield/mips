#!/bin/bash

yosys mips.v -p "prep -top top -flatten; write_json mips.json"
netlistsvg -o mips.svg mips.json