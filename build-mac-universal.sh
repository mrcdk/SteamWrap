#!/bin/bash

cd native

echo "Building Intel 64 bits"
haxelib run hxcpp Build.xml -DHXCPP_M64

echo "Building ARM 64 bits"
haxelib run hxcpp Build.xml -DHXCPP_ARM64

cd ..

mkdir ndll/MacUniversal

echo "Building Universal binary"
lipo -create ndll/Mac64/steamwrap.ndll ndll/MacArm64/steamwrap.ndll -output ndll/MacUniversal/steamwrap.ndll