# Quick Start Guide - Pet Connect AI Features

## 🚀 Get Started in 5 Minutes

### 1. Verify Dependencies

Run this command to ensure all dependencies are installed:

```bash
cd /Users/amaymalviya/Documents/Development/MajorPP/pet_connect/Frontend
flutter pub get
```

### 2. Run the App

```bash
flutter run -d 00008101-001168EE1A05001E  # Your device ID
# or
flutter run  # For default device
```

### 3. Test Global AI Chat

1. **Navigate to Home Screen** → You'll see the new FAB labeled "🎯 Pet AI"
2. **Click the FAB** → Opens GlobalAIChatScreen
3. **Select a Pet** (if you have any) from the dropdown
4. **Type a question** like "What should I feed my dog?"
5. **See AI Response** - Wait for Groq API to respond (~2-3 seconds)

### 4. Test Pet Care AI

These screens are ready but need to be integrated into your existing dashboard:

**To Test Manually**:
```dart
// Navigate to:
import 'package:pet_connect_app/screens/pet_care_ai_screen.dart';

// Push screen:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PetCareAIScreen(
      pet: myPet,  // Your pet object
      topic: 'grooming',
      topicTitle: 'Grooming Tips',
    ),
  ),
);
```

### 5. Test Enhanced Shop Screen

1. **Navigate to Shop Screen** → Should show pet selector now
2. **Select a Pet** → Categories dynamically filter
3. **Click ⭐ AI Button** → Get product suggestions
4. **View Products** with new details: Price, Rating, Source Website

### 6. Test Enhanced Map

1. **Navigate to Services/Map Screen**
2. **Try Different Filters**:
   - 🏥 Veterinary Clinics
   - 🛍️ Pet Shops
   - 🏠 Animal Shelters
   - ❤️ NGOs
   - 🐾 All Services

---

## ⚙️ Configuration Quick Reference

### API Keys (Configuration)

API keys are no longer hardcoded in the app.
Set these values in a `.env` file or via environment configuration:

```
GROQ_API_KEY_GLOBAL=<your_global_key>
GROQ_API_KEY_PET_CARE=<your_pet_care_key>
GROQ_API_KEY_SHOPPING=<your_shopping_key>
```

**⚠️ For Production**: Keep keys secret and do not commit them to source control.

### HERE Maps (Optional)

If you want map features using HERE Maps, you can set the API key via `.env` or using `--dart-define`:

**Option A: Use `.env`** (recommended for local development)

```ini
HERE_API_KEY=your_key
```

**Option B: Use dart-define** (useful in CI or when building release versions)

```bash
flutter run --dart-define=HERE_API_KEY=your_key
```

### No Additional Setup Required

- ✅ Groq APIs are already configured
- ✅ OpenStreetMap Overpass is public
- ✅ SQLite/SharedPreferences work out of the box

---

## 🧪 Test Scenarios

### Scenario 1: First Time User

1. Launch app
2. Click Pet AI FAB
3. Should show "Start your pet conversation" message
4. Select a pet from empty list message
5. Type question
6. Get response

**Expected**: Chat works, pet selection optional

### Scenario 2: Returning User

1. Launch app
2. Click Pet AI FAB
3. Previous conversation loads from cache
4. Can continue or clear history

**Expected**: Conversation history is preserved

### Scenario 3: Shopping with Multiple Pets

1. Go to Shop screen  
2. Select first pet → Categories update
3. Select second pet → Different categories appear
4. Back to first pet → Original categories return

**Expected**: Categories correctly update based on pet type

### Scenario 4: Map with All Services

1. Open map
2. Click "🐾 All Services"
3. Should see markers for all 4 types

**Expected**: Multiple markers from different APIs

---

## 🔍 Debug Tips

### Check Conversation Cache

In Android Studio Console after running app:

```dart
// Add temporary debug code in ai_service.dart
print('Cached conversations: ${_conversationCache.keys}');
print('Cache stats: ${getCacheStats()}');
```

### Monitor API Calls

Use browser DevTools (if running web version) or Wireshark to see:

```
POST https://api.groq.com/openai/v1/chat/completions
GET https://overpass-api.de/api/interpreter
GET https://discover.search.hereapi.com/v1/discover
```

### Test Offline

1. Enable offline mode in DevTools
2. Chat will use cached messages
3. New messages will fail gracefully

### Check Memory Usage

In Android Studio:
- Profiler → Memory
- Watch cache size with growing number of messages
- Should be < 10MB for typical usage

---

## 📱 Platform-Specific Notes

### Android
- ✅ Works as-is
- ✅ Location permissions handled by existing `map_screen.dart`
- ℹ️ External URL launch works with Chrome/default browser

### iOS
- ✅ Should work (Dart code is platform-agnostic)
- ⚠️ May need location permission in Info.plist
- ⚠️ Test URL launching with Safari

### Web
- ⚠️ Map screen may have CORS issues with Overpass API
- ⚠️ HERE Maps requires CORS configuration
- ✅ Chat and shopping fully functional

---

## 🎨 Customize Look & Feel

### Change Primary Color

All AI screens use `AppTheme.primaryColor`. To change:

**File**: `lib/theme/app_theme.dart`

```dart
static const Color primaryColor = Color(0xFF6366F1);  // Change this
```

### Adjust Font Sizes

All screens use `GoogleFonts.poppins`. Adjust scale:

```dart
Text(
  'Sample',
  style: GoogleFonts.poppins(
    fontSize: 14,  // Change this
    fontWeight: FontWeight.bold,
  ),
);
```

### Customize Quick Questions

Edit in `pet_care_ai_screen.dart`:

```dart
List<String> _getQuickQuestions() {
  switch (widget.topic.toLowerCase()) {
    case 'grooming':
      return [
        'Custom question 1',
        'Custom question 2',
        // ...
      ];
  }
}
```

---

## 📊 Monitoring Checklist

- [ ] Open app first time → Global AI Chat works
- [ ] Send message → Response appears in ~2-3 seconds
- [ ] Pet selection → Works in both chat and shopping
- [ ] Shop filtering → Categories update correctly
- [ ] AI suggestions → Panel appears with recommendations
- [ ] Map filters → Service markers update appropriately
- [ ] Close and reopen app → Chat history persists
- [ ] No crashes or exceptions in console output
- [ ] Images load in product cards
- [ ] Search in products filters correctly
- [ ] Multiple pets handled correctly
- [ ] Network errors handled gracefully

---

## 🚨 Troubleshooting Quick Fixes

### "AI Service Error"
```dart
// Fix: Ensure initialization completed
print('AIService initialized: $_isInitialized');
```

### "No products shown"
```dart
// Fix: Verify Product model has id field
// Check: lib/models/product.dart has 'id' parameter
```

### "Map shows nothing"
```dart
// Fix: Ensure location permission granted
// Enable: Settings > Location > Pet Connect
```

### "Categories not updating"
```dart
// Fix: Verify pet.animal is populated
print('Pet type: ${pet.animal}');
```

### "Chat messages disappear"
```dart
// Fix: Check SharedPreferences initialization
// Verify: AIService.initialize() called before use
```

---

## 📚 Documentation Files

1. **AI_FEATURES_GUIDE.md** - Complete detailed documentation
2. **IMPLEMENTATION_SUMMARY.md** - What was built and checklist
3. **QUICK_START.md** - This file for immediate testing

---

## 🎯 Next Steps After Testing

1. **Integrate Pet Care AI** into your existing dashboard screens
2. **Verify Product Data** in Supabase has all required fields
3. **Test with Real Data** from your database
4. **Gather User Feedback** on AI quality
5. **Monitor API Usage** and costs
6. **Move API Keys** to secure storage for production

---

## ✨ Features You Can Now Show Users

1. ✅ "Chat with our AI pet expert" - Global AI Chat
2. ✅ "Get personalized pet care advice" - Pet Care AI (4 topics)
3. ✅ "Smart product recommendations" - Shopping AI
4. ✅ "Find nearby pet services" - Enhanced Map

---

## 🤝 Need Help?

Refer to:
- **General questions**: Check AI_FEATURES_GUIDE.md
- **What was implemented**: Check IMPLEMENTATION_SUMMARY.md
- **API issues**: Check Groq, Overpass, or HERE docs
- **Flutter issues**: Check Flutter debug console

---

**Happy Testing!** 🐾

Report any bugs or improvements needed in the implementation.
