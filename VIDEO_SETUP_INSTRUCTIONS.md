# Sea Turtle Video Setup Instructions

## Quick Setup (2 minutes)

The sea turtle animation video is included in the project but needs to be added to Xcode's build system.

### Steps:

1. **Open the project** in Xcode
   - Double-click `BnBFox.xcodeproj`

2. **Locate the video file**
   - In Finder, navigate to: `BnBFox/BnBFox/sea-turtle-swimming.mov`
   - The file is already in the correct location (48MB)

3. **Add to Xcode project**
   - In Xcode's left sidebar (Project Navigator), select the `BnBFox` folder
   - Drag `sea-turtle-swimming.mov` from Finder into the Xcode project navigator
   - **Important:** In the dialog that appears:
     - ✅ Check "Copy items if needed"
     - ✅ Make sure "BnBFox" target is selected
     - Click "Finish"

4. **Verify it's added**
   - You should see `sea-turtle-swimming.mov` in the project navigator
   - Select it and check the File Inspector (right sidebar)
   - Under "Target Membership", ensure "BnBFox" is checked

5. **Build and run**
   - Press Cmd+R or click the Play button
   - You should see the beautiful swimming sea turtle during loading!

## What Changed

### ✅ Fixed Issues:
- **Duplicate month header** - "December 2025" no longer appears twice
- **Missing infinite scroll** - Calendar now shows 6 months back + 12 months forward
- **Slow loading** - Progressive loading shows current month instantly

### 🚀 Performance Improvements:
- **Instant display** - Current month appears immediately
- **Progressive expansion** - Full calendar loads 0.1 seconds later
- **Smooth scrolling** - LazyVStack only renders visible months
- **Fast user experience** - No more waiting for all data

### 🎬 Loading Screen:
- Full-screen animated sea turtle
- Professional Adobe Stock video (1920x1080, 60fps)
- Seamless looping during data load
- Text: "Loading your Kawama Calendar"

## Troubleshooting

### Video doesn't show:
- Check console for "Error: Could not find sea-turtle-swimming.mov"
- If you see this error, the video wasn't added to the build
- Follow steps 3-4 above to add it properly

### App crashes on launch:
- Clean build folder: Product → Clean Build Folder (Cmd+Shift+K)
- Rebuild: Product → Build (Cmd+B)
- Run again

### Still having issues:
- Make sure the video file is in `BnBFox/BnBFox/` directory
- Check that file size is ~48MB
- Verify target membership is set to "BnBFox"

## Technical Details

**Video Specifications:**
- Format: MOV (H.264)
- Resolution: 1920x1080 (Full HD)
- Frame rate: 60fps
- Duration: ~7 seconds
- File size: 48MB
- Source: Adobe Stock (licensed)

**Implementation:**
- Uses AVKit's VideoPlayer for native playback
- Aspect fill to maximize screen coverage
- Auto-loops seamlessly
- Black background with white text overlay
- Loading spinner at bottom

**Progressive Loading:**
- Initial: Shows current month only (fast!)
- After 0.1s: Expands to 19 months (6 back + current + 12 forward)
- LazyVStack: Only renders visible months for performance
- Smooth animation during expansion
