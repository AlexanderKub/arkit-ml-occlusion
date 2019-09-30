# arkit-ml-occlusion
Arkit-ml-occlusion is a proof of concept augmented reality project based on ARKit for handle occlusion using ML.
In this version implemented masked occlusion with people, this means that all people in the frame would occlude the AR scene.
This project use [Fritz](https://www.fritz.ai/)  machine learning platform [image segmentation](https://docs.fritz.ai/develop/vision/image-segmentation/ios.html).

### Example
For run example project you must get a free account on [Fritz](https://www.fritz.ai/) site. Add your Bundle identifier the `Fritz-Info.plist` file to your app ([Guide](https://docs.fritz.ai/quickstart.html#ios)).
To run the example project, clone the repo, and run `pod install`.
Build and run arkit-ml-occlusion project target.

### Enviroment
I using:
- Xcode 10.3
- Fritz 4.0.1

Testing on:
- iPhone SE
- iOS 12.4.1

![screenshot1](https://github.com/AlexanderKub/arkit-ml-occlusion/raw/master/screenshots/screenshot01.jpeg)
![screenshot2](https://github.com/AlexanderKub/arkit-ml-occlusion/raw/master/screenshots/screenshot02.jpeg)
