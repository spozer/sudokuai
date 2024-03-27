#!/bin/bash

# This script downloads the needed jni libs and headers for this project

TF_URL="https://repo1.maven.org/maven2/org/tensorflow/tensorflow-lite/2.15.0/tensorflow-lite-2.15.0.aar"
CV_URL="https://github.com/opencv/opencv/releases/download/4.9.0/opencv-4.9.0-android-sdk.zip"

# absolute paths
JNI_DIR=$(pwd)/android/src/main/jniLibs
INCLUDE_DIR=$(pwd)/includes

mkdir -p $JNI_DIR/arm64-v8a
mkdir -p $JNI_DIR/armeabi-v7a
mkdir -p $JNI_DIR/x86
mkdir -p $JNI_DIR/x86_64
mkdir -p $INCLUDE_DIR
mkdir setup && cd setup

function setup {
    name=$1
    url=$2
    include_dir=$3
    lib_dir=$4

    printf "Downloading $name\n"
    curl -L $url -o "$name.zip"
    mkdir $name && cd $name
    printf "Extracting $name\n"
    unzip -q ../"$name.zip" $include_dir/* $lib_dir/*
    printf "Moving headers and lib for $name\n"
    mv $include_dir/* $INCLUDE_DIR
    mv $lib_dir/arm64-v8a/* $JNI_DIR/arm64-v8a
    mv $lib_dir/armeabi-v7a/* $JNI_DIR/armeabi-v7a
    mv $lib_dir/x86/* $JNI_DIR/x86
    mv $lib_dir/x86_64/* $JNI_DIR/x86_64
    cd ..
}

# TensorFlow Lite
# paths inside zip archive
TF_INCLUDE_DIR="headers"
TF_LIB_DIR="jni"
setup "tflite" $TF_URL $TF_INCLUDE_DIR $TF_LIB_DIR

# OpenCV
# paths inside zip archive
CV_INCLUDE_DIR="OpenCV-android-sdk/sdk/native/jni/include"
CV_LIBS_DIR="OpenCV-android-sdk/sdk/native/libs"
setup "opencv" $CV_URL $CV_INCLUDE_DIR $CV_LIBS_DIR

printf "Clean up\n"
cd ..
rm -rf setup
