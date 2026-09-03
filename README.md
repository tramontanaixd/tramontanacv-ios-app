# tramontanaCV

Use your phone's computing power to sense people or objects in space. Collect and manipulate data from Processing.

Inspired by [openTSPS](https://github.com/LAB-at-RockwellGroup/openTSPS) by LAB at Rockwell Group.

## Setup

1. Download tramontanaCV for iOS (Android coming soon)
2. Join the same WiFi network as your laptop
3. Send data from your phone to your Processing sketch in seconds

## Remote Control (v2.0+)
```java
lockExposure() 
unlockExposure() 
captureBackground()
takeScreenshot()
setBlur(float) 
setThreshold(int) 
setBlobs(int min, int max, int num)
setCamera(int) 
switchToDetectFaces() 
switchToDetectBlobs()
```

## Callbacks
```java
onBoundingBoxReceived(TBBoxContainer container, int nBboxes, String ip)

onBlobsReceived(TBlobsContainer container, int nBlobs, String ip)

onFacesReceived(TBBoxContainer container, int nFaces, String ip)
```

## Types

```java
TBBoxContainer { TBBox[] bboxes; int nBBoxes; }
TBBox { public float x, y, w, h; }

TBlobsContainer { TBlob[] blobs; int nBlobs; }
TBlob { TVector[] pts; int nPts; void draw(); }

TVector { int x, y; }
```