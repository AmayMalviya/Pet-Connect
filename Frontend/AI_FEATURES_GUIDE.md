# Pet Connect AI Features - Implementation Guide

## Overview

This document provides a comprehensive guide to the AI-powered features implemented in the Pet Connect Flutter app. These features leverage Groq's LLM API, HERE Maps, and OpenStreetMap to provide intelligent pet care assistance, smart shopping, and service discovery.

---

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [AI Modes](#ai-modes)
3. [Installation & Setup](#installation--setup)
4. [Feature Documentation](#feature-documentation)
5. [API Keys & Configuration](#api-keys--configuration)
6. [File Structure](#file-structure)
7. [Usage Examples](#usage-examples)
8. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### Technology Stack

- **Frontend**: Flutter 3.9+
- **Backend**: Supabase
- **AI/LLM**: Groq (llama3-70b-8192)
- **Maps**: HERE Maps + OpenStreetMap Overpass API
- **State Management**: StatefulWidget with Service classes
- **Local Storage**: SharedPreferences (for conversation caching)

### Core Services

#### 1. `AIService` (`lib/services/ai_service.dart`)
- **Purpose**: Handles all Groq LLM API interactions
- **Modes**: global, pet_care, shopping
- **Features**:
  - Multi-mode AI conversations
  - Pet context awareness
  - Conversation caching with SharedPreferences
  - Token usage tracking

#### 2. `ProductService` (`lib/services/product_service.dart`)
- **Purpose**: Pet-specific product filtering and management
- **Features**:
  - Pet type-based product filtering
  - Category-based filtering
  - Price range filtering
  - Rating-based filtering
  - AI product recommendation parsing
  - Product deduplication

#### 3. `MapService` (`lib/services/map_service.dart`)
- **Purpose**: Nearby pet services discovery
- **APIs Used**:
  - OpenStreetMap Overpass API
  - HERE Maps (via map_screen.dart)
- **Features**:
  - Veterinary clinic detection
  - Pet shop discovery
  - Animal shelter location
  - NGO/Wildlife organization finding
  - Distance calculation
  - Location caching

---

## AI Modes

### Mode 1: Global AI Chat 🤖

**Access Point**: Floating Action Button on Home Screen (labeled "Pet AI")

**Use Case**: General pet-related questions and advice

**Context Sent to AI**:
- Selected pet profile (optional)
- User's question
- Pet type, breed, age, weight

**Features**:
- Real-time chat interface
- Pet selection support
- Message history
- Warm, encouraging responses
- Focus on pet care best practices

**API Key**: Set via `.env` using `GROQ_API_KEY_GLOBAL` (or your own secret key)

**Screen**: `GlobalAIChatScreen` (`lib/screens/global_ai_chat_screen.dart`)

### Mode 2: Pet Care AI 🐾

**Access Points**: 
- Dedicated screens for each topic
- Topics: Grooming, Diet, Exercise, Training

**Use Case**: Specific pet care guidance

**Context Sent to AI**:
- Complete pet profile
- Current topic (grooming/diet/exercise/training)
- User's specific question

**Features**:
- Topic-specific suggestions
- Quick question templates
- Real-time responses
- Pet-specific recommendations

**API Key**: Set via `.env` using `GROQ_API_KEY_PET_CARE` (or reuse `GROQ_API_KEY_GLOBAL`)

**Screen**: `PetCareAIScreen` (`lib/screens/pet_care_ai_screen.dart`)

**Topics**:
1. **Grooming** 🧴
   - Bathing frequency & techniques
   - Coat care tips
   - Nail trimming guidance
   - Grooming tool recommendations

2. **Diet** 🍖
   - Nutrition advice
   - Food recommendations
   - Feeding schedules
   - Toxic food warnings

3. **Exercise** 🏃
   - Activity recommendations
   - Exercise duration guidelines
   - Indoor activity ideas
   - Fitness for specific ages

4. **Training** 📚
   - Command teaching
   - Behavioral correction
   - Positive reinforcement techniques
   - House training tips

### Mode 3: Shopping AI 🛍️

**Access Point**: Shop Screen (AI button next to search)

**Use Case**: AI-powered product discovery

**Context Sent to AI**:
- Selected pet type
- Pet age
- User's search query
- Category preferences

**Features**:
- Contextual product suggestions
- Pet-appropriate recommendations
- Smart filtering
- Category suggestions

**API Key**: Set via `.env` using `GROQ_API_KEY_SHOPPING` (or reuse `GROQ_API_KEY_GLOBAL`)

**Integration**: Enhanced ShopScreen with:
- Pet selector
- Dynamic category filtering
- AI suggestion panel
- Improved product cards with ratings & source

---

## Installation & Setup

### Step 1: Add Dependencies

Already added to `pubspec.yaml`:
```yaml
dio: ^5.3.0
shared_preferences: ^2.2.0
uuid: ^4.0.0
google_maps_flutter: ^2.6.1
```

### Step 2: Initialize Services

In your main app initialization:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_KEY',
  );
  
  runApp(const MyApp());
}
```

### Step 3: Initialize AI Service

In your home screen or app initialization:

```dart
final aiService = AIService();
await aiService.initialize();
```

### Step 4: Initialize Product Service

```dart
final productService = ProductService();
await productService.initialize();
```

---

## Feature Documentation

### 1. Global AI Chat Feature

#### Files Involved
- `GlobalAIChatScreen` - Main UI
- `AIService` - Backend logic
- `AIMessage` - Data model

#### How It Works
1. User opens chat via FAB
2. Selects a pet (optional)
3. Types question
4. AI responds with pet-aware advice
5. Conversation is cached

#### Example Interactions
```
User: "My dog has been sleeping too much, is that normal?"
AI: [Provides age-aware health advice and recommends vet consultation]

User: "What treats are safe for my cat?"
AI: [Lists safe treats and toxic foods for cats]
```

#### Implementation Details
- Messages stored in SharedPreferences with conversation ID
- Groq API call includes pet context
- Max 1000 tokens per response
- Temperature: 0.7 (balanced creativity)

---

### 2. Pet Care AI Feature

#### Files Involved
- `PetCareAIScreen` - Topic-specific UI
- `AIService` - Backend with pet_care mode
- Routes to integrate: grooming_details_screen, diet_details_screen, etc.

#### Integration Points

**Grooming Screen**:
```dart
// Navigate to Pet Care AI
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PetCareAIScreen(
      pet: pet,
      topic: 'grooming',
      topicTitle: 'Grooming Tips',
    ),
  ),
);
```

**Diet Screen**:
```dart
PetCareAIScreen(
  pet: pet,
  topic: 'diet',
  topicTitle: 'Diet & Nutrition',
)
```

**Exercise Screen**:
```dart
PetCareAIScreen(
  pet: pet,
  topic: 'exercise',
  topicTitle: 'Exercise & Activity',
)
```

**Training Screen**:
```dart
PetCareAIScreen(
  pet: pet,
  topic: 'training',
  topicTitle: 'Training & Behavior',
)
```

#### Quick Questions Feature
Each screen shows 4 contextual questions based on topic:

- **Grooming**: Bathing frequency, brushing tips, nail care, tool recommendations
- **Diet**: Food recommendations, feeding amounts, toxic foods, age-specific nutrition
- **Exercise**: Activity needs, duration, indoor ideas, fitness by age
- **Training**: Basic commands, behavior issues, reinforcement, housetraining

---

### 3. Pet-Based Shopping Feature

#### Files Involved
- **Enhanced ShopScreen** (`lib/screens/shop_screen.dart`)
- `ProductService` - Filtering logic
- `Product` model - Enhanced with rating, sourceWebsite, category

#### Pet Categories Mapping

```dart
{
  'dog': ['food', 'toys', 'leash', 'grooming kit', 'beds', 'treats', 'bowls', 'collars'],
  'cat': ['food', 'litter', 'scratchers', 'toys', 'beds', 'treats', 'bowls', 'litter box'],
  'bird': ['food', 'cage', 'toys', 'perches', 'treats', 'sand bath', 'mirrors'],
  'rabbit': ['food', 'hay', 'toys', 'bedding', 'tunnels', 'treats', 'bowls'],
  'hamster': ['food', 'bedding', 'wheel', 'toys', 'treats', 'hidehouse', 'bowls'],
}
```

#### How It Works
1. User selects a pet
2. Categories dynamically populate based on pet type
3. User can filter by category
4. Search in selected categories
5. AI can suggest products
6. Products show: name, price, rating, source website
7. "View Product" button opens external link

#### Product Card Features
- Pet-appropriate category filtering
- Rating display with stars
- Source website attribution
- External link button
- Image with fallback
- Clean, modern design

---

### 4. Nearby Pet Services Feature

#### Files Involved
- **Enhanced MapScreen** (`lib/screens/map_screen.dart`)
- `MapService` - Overpass API integration
- `ServiceLocation` model

#### Service Types
1. **Veterinary Clinics** 🏥
   - Animal hospitals
   - Vet practices
   - Emergency pet care

2. **Pet Shops** 🛍️
   - Pet supplies retailers
   - Grooming services
   - Pet care products

3. **Animal Shelters** 🏠
   - Adoption centers
   - Dog/cat rescues
   - Humane societies

4. **NGOs** ❤️
   - Animal welfare organizations
   - Wildlife sanctuaries
   - Pet protection groups

#### How It Works
1. User opens map screen
2. Clicks filter chip to select service type
3. Map displays nearby services
4. Each marker shows location, name, rating
5. Click marker for details and HERE Maps navigation
6. "All Services" shows mixed results

#### Overpass API Queries
- **Veterinary**: `[amenity="veterinary"]`
- **Pet Shops**: `[shop="pet"]`
- **Shelters**: `[amenity="animal_shelter"]`
- **NGOs**: Dynamic keyword search

#### Distance Calculation
Uses Haversine formula to calculate distance from user location. Sorted by distance ascending.

---

### 5. Caching & Performance

#### Implementation
- **AIService**: Converts messages to JSON, stores conversation with unique ID
- **ProductService**: LRU cache for filtered products
- **MapService**: Location-based cache with key: `{serviceType}_{latitude}_{longitude}`

#### Cache Management
```dart
// Clear specific service type cache
mapService.clearCacheForType('veterinary');

// Clear all caches
mapService.clearCache();

// Get cache statistics
final stats = mapService.getCacheStats();
```

---

## API Keys & Configuration

### Groq API Keys

Three separate API keys for different modes:

1. **Global Chat AI**
   - Key: set via `.env` using `GROQ_API_KEY_GLOBAL`
   - Uses: Global chat, general pet questions

2. **Pet Care AI**
   - Key: set via `.env` using `GROQ_API_KEY_PET_CARE` (or reuse `GROQ_API_KEY_GLOBAL`)
   - Uses: Grooming, diet, exercise, training

3. **Shopping AI**
   - Key: set via `.env` using `GROQ_API_KEY_SHOPPING` (or reuse `GROQ_API_KEY_GLOBAL`)
   - Uses: Product recommendations, shopping assistance

### HERE Maps Configuration

Add to your `.env` file or pass via build parameters:
```
HERE_API_KEY=your_here_api_key
HERE_ACCESS_KEY_ID=your_access_key_id
HERE_ACCESS_KEY_SECRET=your_access_key_secret
```

Or pass via flutter run:
```bash
flutter run --dart-define=HERE_API_KEY=your_key
```

### Groq API Endpoint
```
https://api.groq.com/openai/v1/chat/completions
```

### Model Configuration
```dart
- Model: llama3-70b-8192
- Temperature: 0.7 (versatility)
- Max Tokens: 500-1000 (based on mode)
- Request Timeout: 30 seconds
```

---

## File Structure

```
lib/
├── models/
│   ├── ai_message.dart         # Chat message & conversation models
│   ├── pet.dart                # Pet model (enhanced)
│   ├── product.dart            # Product model (enhanced with rating, source)
│   ├── service_location.dart   # Nearby service location model
│   └── ... (other models)
│
├── services/
│   ├── ai_service.dart         # Groq integration for 3 modes
│   ├── product_service.dart    # Pet-specific product filtering
│   ├── map_service.dart        # OpenStreetMap & HERE Maps integration
│   └── ... (other services)
│
├── screens/
│   ├── global_ai_chat_screen.dart       # Main AI chat screen
│   ├── pet_care_ai_screen.dart          # Topic-specific care screens
│   ├── shop_screen.dart                 # Enhanced shop with filters
│   ├── map_screen.dart                  # Enhanced map with service filters
│   ├── home_screen.dart                 # Updated with AI FAB
│   ├── main_screen.dart                 # Container with FAB
│   └── ... (other screens)
│
├── theme/
│   └── app_theme.dart          # Contains AppTheme class used throughout
│
└── pubspec.yaml               # Updated with dio, shared_preferences, uuid
```

---

## Usage Examples

### Example 1: Using Global AI Chat

```dart
// User taps FAB on home screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const GlobalAIChatScreen()),
);

// In UI:
// 1. Chat interface loads with cached conversation
// 2. User selects a pet (optional dropdown showing user's pets)
// 3. User types: "My dog keeps eating grass, is it bad?"
// 4. AI responds with pet-specific health advice
// 5. Conversation is automatically cached
```

### Example 2: Using Pet Care AI for Diet

```dart
// From pet dashboard, user taps "Ask AI" on diet card
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PetCareAIScreen(
      pet: myPet,
      topic: 'diet',
      topicTitle: 'Diet & Nutrition',
    ),
  ),
);

// User sees quick questions:
// - "What's the best food for my dog?"
// - "How much should I feed daily?"
// - "What foods are toxic for dogs?"
// - "Diet recommendations for 5 year old"

// User taps a quick question or types custom question
// AI responds with pet-specific nutrition advice
```

### Example 3: Using Shopping AI

```dart
// User is on shop screen
// 1. Selects pet from dropdown (e.g., "Max - Dog")
// 2. Categories automatically show dog categories
// 3. User clicks AI button and types: "Best toys for an active dog"
// 4. AI suggests products in reply panel
// 5. User can click suggested products or browse filtered results
// 6. Each product shows: name, price ⭐ rating, source website
// 7. "View Product" button opens URL externally
```

### Example 4: Finding Nearby Pet Services

```dart
// User opens map screen
// 1. Map shows current location + veterinary clinics (default)
// 2. User clicks "🛍️ Pet Shops" filter
// 3. Map updates to show pet shops
// 4. User clicks "❤️ NGOs" filter
// 5. Map shows NGOs
// 6. User clicks marker to see details
// 7. Option to open in HERE Maps for navigation
```

---

## Troubleshooting

### Issue 1: AI Service Not Initializing

**Symptoms**: Chat screens stuck on loading or throwing "AI Service Error"

**Solutions**:
```dart
// Ensure initialization is awaited
await aiService.initialize();

// Check API key is correct
// Verify internet connection
// Check Groq API status
```

### Issue 2: Products Not Filtering Correctly

**Symptoms**: Products from other pet types appearing in filtered view

**Solutions**:
```dart
// Verify Product model has pet_type field populated
// Check ProductService filter logic
// Ensure categories are in the petCategories mapping
```

### Issue 3: Map Showing Nothing

**Symptoms**: Map loads but no markers appear

**Solutions**:
```dart
// Verify HERE API key is set correctly
// Check location permissions are granted
// Ensure Overpass API is accessible (not rate-limited)
// Try different filter (start with vets)
```

### Issue 4: Conversation History Lost

**Symptoms**: Chat messages disappear after app restart

**Solutions**:
```dart
// SharedPreferences not initialized properly
// Fix: Ensure AIService.initialize() is called early
// Check device storage permissions
// Verify conversation ID is consistent
```

### Issue 5: API Rate Limiting

**Symptoms**: "Too many requests" errors from Groq or Overpass API

**Solutions**:
```dart
// Groq: Wait between requests (implement request queuing)
// Overpass: Add delay between API calls
// MapService: Implement caching (already done)
```

---

## Performance Optimization Tips

1. **Cache Conversations**: Already implemented with SharedPreferences
2. **Lazy Load Products**: Filter before API calls
3. **Batch Map Requests**: Group multiple service searches
4. **Reuse Service Instances**: Singleton pattern for services
5. **Limit Token Usage**: Adjust max_tokens based on actual needs

---

## Future Enhancement Ideas

1. **Offline Support**: Sync cached data when online
2. **Multi-Language Support**: Groq can translate responses
3. **Advanced Filtering**: Price range, ratings, reviews
4. **Product Comparison**: Side-by-side product comparison
5. **Service Booking**: Integration with booking APIs
6. **Voice Input/Output**: Text-to-speech for responses
7. **Custom AI Training**: Fine-tune model with pet-specific data
8. **Community Ratings**: User reviews of products/services
9. **Emergency Services Highlight**: Prioritize emergency vets
10. **Recurring Questions**: FAQ based on popular queries

---

## Support & Maintenance

### API Monitoring
- Monitor Groq API usage and costs
- Track OpenStreetMap Overpass API rate limits
- Monitor SharedPreferences storage usage

### Security
- API keys are in code (development) - move to secure storage for production
- Implement API rate limiting on client side
- Validate all user inputs before sending to APIs

### Testing
- Test with different pet types and ages
- Test offline scenarios
- Test with slow network connections
- Monitor memory usage with chat history

---

## Contact & Resources

- **Groq API Docs**: https://console.groq.com/docs
- **OpenStreetMap Overpass**: https://overpass-api.de/
- **HERE Maps**: https://developer.here.com/
- **Flutter Documentation**: https://flutter.dev/docs

---

**Last Updated**: March 14, 2026
**Version**: 1.0.0
