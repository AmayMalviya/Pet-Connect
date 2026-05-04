import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://goegjrqmyshnzzonfjav.supabase.co/rest/v1/pet_products');
  final headers = {
    'apikey': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdvZWdqcnFteXNobnp6b25mamF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc0OTMyOTAsImV4cCI6MjA3MzA2OTI5MH0.i4KPxTg_d85Pd8vXMdOYxvoHdrVDZNmGaz30x1ZBglU',
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdvZWdqcnFteXNobnp6b25mamF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc0OTMyOTAsImV4cCI6MjA3MzA2OTI5MH0.i4KPxTg_d85Pd8vXMdOYxvoHdrVDZNmGaz30x1ZBglU',
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal'
  };

  final products = [
    {
      "name": "Premium Adult Dog Food",
      "price": "45.99",
      "image_url": "https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=500&q=80",
      "category": "Food",
      "pet_type": "dog",
      "species": ["dog"],
      "rating": 4.8
    },
    {
      "name": "Interactive Cat Laser Toy",
      "price": "15.99",
      "image_url": "https://images.unsplash.com/photo-1545249390-6bdfa286032f?w=500&q=80",
      "category": "Toys",
      "pet_type": "cat",
      "species": ["cat"],
      "rating": 4.5
    },
    {
      "name": "Orthopedic Dog Bed",
      "price": "65.00",
      "image_url": "https://images.unsplash.com/photo-1541599540903-216a46ca1dc0?w=500&q=80",
      "category": "Beds",
      "pet_type": "dog",
      "species": ["dog"],
      "rating": 4.9
    },
    {
      "name": "Natural Cat Grooming Brush",
      "price": "12.50",
      "image_url": "https://images.unsplash.com/photo-1513245543132-31f507417b26?w=500&q=80",
      "category": "Grooming",
      "pet_type": "cat",
      "species": ["cat"],
      "rating": 4.6
    },
    {
      "name": "Heavy Duty Dog Leash",
      "price": "22.99",
      "image_url": "https://images.unsplash.com/photo-1605897472359-85e4b94d685d?w=500&q=80",
      "category": "Accessories",
      "pet_type": "dog",
      "species": ["dog"],
      "rating": 4.7
    },
    {
      "name": "Bird Seed Mix",
      "price": "18.50",
      "image_url": "https://images.unsplash.com/photo-1552728089-571ebf4eb70c?w=500&q=80",
      "category": "Food",
      "pet_type": "bird",
      "species": ["bird"],
      "rating": 4.4
    },
    {
      "name": "Cat Scratching Post",
      "price": "34.99",
      "image_url": "https://images.unsplash.com/photo-1623387641168-d9803ddd3f35?w=500&q=80",
      "category": "Toys",
      "pet_type": "cat",
      "species": ["cat"],
      "rating": 4.8
    },
    {
      "name": "Dog Chew Bone",
      "price": "8.99",
      "image_url": "https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=500&q=80",
      "category": "Toys",
      "pet_type": "dog",
      "species": ["dog"],
      "rating": 4.3
    }
  ];

  final response = await http.post(url, headers: headers, body: jsonEncode(products));
  print(response.statusCode);
  print(response.body);
}
