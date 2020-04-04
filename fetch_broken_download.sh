#!/bin/bash
mkdir temprtc
cd temprtc 
git clone https://github.com/mesibo/mesibowebrtcparts
cat mesibowebrtcparts/webrtc* > ../WebRTC.framework/WebRTC1
cd ..
rm -fr temprtc


