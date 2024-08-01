
# Postick - AR Poster Application

## Introduction
**Postick** is an augmented reality (AR) application that allows users to design, display, and interact with posters in their real-world environment. Utilizing AR technology, users can project posters onto walls, move, resize, rotate, and even create collages from their images. This README provides an overview of the project, its features, and how to use it.

## Features
- **AR Poster Display**: Select an image from your photo library and display it as a poster in your AR view.
- **Interactive Gestures**: Move, resize, and rotate the poster using intuitive touch gestures.
- **Collage Creation**: Combine two images into a vertical or horizontal collage.
- **Photo Capture**: Take a snapshot of your AR view with the displayed posters.
- **Save Collages**: Save the created collages directly to your photo library.
- **AR Coaching**: Guidance provided to help users scan and detect planes in their environment for optimal poster placement.

## Components

### ARViewContainer
A SwiftUI view that integrates `ARView` from RealityKit to display and interact with AR content.

- **Gesture Recognizers**: Handles pan, pinch, rotation, and long press gestures for interactive poster manipulation.
- **Plane Detection**: Detects both horizontal and vertical planes to place posters accurately on walls.
- **Photo Capture**: Captures the AR view including the posters and saves it to the photo library.

### ContentView
The main view that hosts the AR experience and controls for selecting images, creating collages, and capturing photos.

- **Bottom Bar**: Contains buttons for opening the photo picker, capturing photos, and navigating to the collage view.
- **Overlay**: Displays a temporary black screen when a photo is captured to mimic the camera shutter effect.

### CollageView
A SwiftUI view that allows users to create collages from two selected images.

- **Template Picker**: Allows users to choose between vertical and horizontal collage layouts.
- **Save Button**: Saves the created collage to the photo library.

### PhotoPicker
A wrapper for `PHPickerViewController` to select images from the photo library within a SwiftUI interface.

### Template Protocol
Defines the methods for generating collages. Implemented by `VerticalTemplate` and `HorizontalTemplate` structs.

## How to Use

### Selecting an Image
1. Tap the **photo** button on the bottom bar to open the photo picker.
2. Select an image from your photo library.
3. The selected image will be displayed as a poster in the AR view.

### Moving, Resizing, and Rotating the Poster
- **Pan Gesture**: Move the poster by dragging it across the screen.
- **Pinch Gesture**: Resize the poster by pinching with two fingers.
- **Rotation Gesture**: Rotate the poster by twisting with two fingers.
- **Long Press Gesture**: Remove the poster by long pressing on it.

### Creating a Collage
1. Tap the **collage** button on the bottom bar to open the photo picker.
2. Select two images from your photo library.
3. Choose a vertical or horizontal layout from the template picker.
4. Tap **Save Collage** to save the collage to your photo library.

### Capturing a Photo
1. Tap the **capture** button (white circle) on the bottom bar to capture the current AR view.
2. The photo will be saved to your photo library, and a black screen overlay will temporarily appear to mimic the camera shutter effect.

## Project Structure
- **ARViewContainer.swift**: Contains the AR view setup and gesture handling logic.
- **ContentView.swift**: Hosts the AR view and the bottom control bar.
- **CollageView.swift**: Provides the UI for creating and saving collages.
- **PhotoPicker.swift**: Wraps the PHPickerViewController for selecting images.
- **Template.swift**: Defines the collage generation logic for different layouts.

## Requirements
- iOS 14.0+
- Xcode 12.0+
- Swift 5.3+

## License
This project is licensed under the MIT License.

## Contact
For any questions or suggestions, please open an issue or contact us at lucienliu987@gmail.com

