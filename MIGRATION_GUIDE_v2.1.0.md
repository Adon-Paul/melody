# 🔄 Migration Guide: MELODY v2.0 → v2.1.0

## 📋 Overview

This guide helps you understand the changes and new features when upgrading from MELODY v2.0 to v2.1.0.

## 🆕 New Features You'll Notice

### 🎛️ **Lyrics System with RGB Effects**
**What's New**: Professional lyrics display with customizable visual effects
- Access through the music player screen
- Three visual modes: Beat sync, RGB effects, or minimal display
- Settings can be adjusted in the player interface
- **Action Required**: None - feature is enabled by default

### 🎪 **Queue Management**
**What's New**: Interactive queue button in the bottom bar
- Tap the queue icon to see upcoming songs
- Drag and drop to reorder tracks
- Tap any song to jump to it immediately
- **Action Required**: None - seamlessly integrated into existing interface

### ⚡ **Performance Improvements**
**What's New**: Intelligent caching system for device music
- First scan may take the same time as before
- Subsequent opens will be 90% faster
- Cache automatically refreshes every 24 hours
- **Action Required**: None - works automatically in the background

## 🔧 Settings & Configuration

### **New Settings Available**
1. **RGB Effects Control**: 
   - Location: Music player → Long press lyrics area
   - Options: Beat sync, RGB effects, Minimal
   - Default: RGB effects enabled

2. **Cache Management**:
   - Location: Device music page
   - Features: Manual refresh button, cache status indicator
   - Automatic: 24-hour refresh cycle

## 💾 Data Migration

### **Automatic Migration**
- ✅ All your favorites are preserved
- ✅ Authentication state remains intact
- ✅ Previous music scanning data is enhanced with caching
- ✅ App preferences carry forward

### **New Data Storage**
- Settings for RGB effects (stored locally)
- Music cache metadata (24-hour validity)
- Queue order preferences (session-based)

## 🎨 UI/UX Changes

### **What's Different**
1. **Queue Button**: New icon in the bottom navigation bar
2. **Spacing Improvements**: Better layout throughout the app
3. **Performance Indicators**: Loading states and progress bars
4. **Cache Status**: Indicators showing cache state in device music

### **What Remains the Same**
- All existing navigation patterns
- Authentication flow
- Music player controls
- Favorites functionality
- Mini player behavior

## 🚨 Known Considerations

### **First Launch After Update**
- Device music page may rebuild cache (one-time process)
- All existing functionality remains available during cache rebuild
- Progress indicator shows cache building status

### **Storage Usage**
- Minimal increase (~1-5MB) for cache metadata
- Actual music files are not duplicated
- Cache can be manually cleared if needed

### **Performance Notes**
- Large music libraries (1000+ songs) will see the biggest improvements
- Smaller libraries will still benefit from optimized loading
- Memory usage is more efficient across all library sizes

## 🔄 Rollback Information

### **If You Need to Downgrade**
- All data remains compatible with v2.0
- New cache files are ignored by older versions
- Settings revert to previous defaults
- No data loss occurs during rollback

### **How to Rollback**
1. Uninstall current version
2. Install v2.0 build
3. Data integrity is maintained

## 🆘 Troubleshooting

### **Common Issues & Solutions**

**Issue**: Device music not loading quickly
**Solution**: 
- Wait for initial cache build (progress shown)
- Use manual refresh if needed
- Large libraries may take 1-2 minutes initially

**Issue**: Queue button not visible
**Solution**: 
- Restart the app
- Ensure you're on the music player screen
- Check that music is currently loaded

**Issue**: RGB effects not working
**Solution**:
- Long press on lyrics area to access settings
- Ensure RGB effects are enabled in settings
- Try switching between different modes

**Issue**: Performance seems slower
**Solution**:
- Wait for cache build completion
- Close and reopen the app
- Clear cache manually if persistent

## 📞 Getting Help

If you encounter issues during migration:

1. **Check the Release Notes**: `RELEASE_NOTES_v2.1.0.md`
2. **GitHub Issues**: [Report bugs](https://github.com/nobodyuwouldknow/melody/issues)
3. **GitHub Discussions**: [Community help](https://github.com/nobodyuwouldknow/melody/discussions)
4. **Email Support**: melody.app.support@gmail.com

## 🎉 Enjoy the New Features!

The v2.1.0 update brings significant performance improvements and powerful new features while maintaining the familiar MELODY experience you love. Take some time to explore the new queue management and lyrics customization options!

---

**🎵 Happy listening with MELODY v2.1.0!**
