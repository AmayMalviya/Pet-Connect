import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  static const String routeName = '/shop';

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _products = _getProducts();
    _filteredProducts = _products;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredProducts = _products
          .where(
            (product) => product.name.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ),
          )
          .toList();
    });
  }

  List<Product> _getProducts() {
    return [
      Product(
        name: 'Dog Food',
        price: '\ 650 Rs',
        imageUrl: 'assets/images/DogFood.png', // Using a placeholder image
        productUrl: 'https://www.google.com/search?q=dog+food&oq=dog+food&gs_lcrp=EgZjaHJvbWUyBggAEEUYOTIHCAEQABiABDIHCAIQABiABDIHCAMQABiABDIMCAQQABgUGIcCGIAEMgkIBRAAGAoYgAQyBwgGEAAYgAQyBwgHEAAYgAQyBggIEAAYgAQyBggJEC4YQNIBCDE3MDJqMGoxqAIIsAIB8QWtvuSWxlIJMQ&sourceid=chrome&ie=UTF-8#pvs=0:~:text=Dry%20Dog%20Food-,Meat,-%26%20Rice',
      ),
      Product(
        name: 'Cat Food',
        price: '\ 400 Rs',
        imageUrl: 'assets/images/CatFood.png', // Using a placeholder image
        productUrl: 'https://www.google.com/search?q=cat+food&sca_esv=87473f56703eda8f&sxsrf=AE3TifOfMqlOal0kERoee_fBrHh3rxxZBA%3A1755752865660&ei=oammaPf-J8uy4-EP-ILdiAs&ved=0ahUKEwi30_uOkZuPAxVL2TgGHXhBF7EQ4dUDCBA&uact=5&oq=cat+food&gs_lp=Egxnd3Mtd2l6LXNlcnAiCGNhdCBmb29kMg0QLhiABBixAxhDGIoFMgoQABiABBhDGIoFMgoQABiABBhDGIoFMgoQABiABBhDGIoFMgoQABiABBhDGIoFMgoQABiABBgUGIcCMgUQABiABDIFEAAYgAQyDRAAGIAEGLEDGEMYigUyBhAAGAcYHjIcEC4YgAQYsQMYQxiKBRiXBRjcBBjeBBjfBNgBAUjiElD0B1iQC3ACeAGQAQCYAdEBoAHBBKoBBTAuMi4xuAEDyAEA-AEBmAIEoAKfA8ICEBAuGLADGNEDGNYEGEcYxwHCAgoQABiwAxjWBBhHwgINEAAYgAQYsAMYQxiKBZgDAIgGAZAGCroGBggBEAEYFJIHBTIuMS4xoAfcF7IHBTAuMS4xuAeYA8IHBTAuMS4zyAcP&sclient=gws-wiz-serp#:~:text=Purepet-,Adult,-Cat%20Ocean%20Fish',
      ),
      Product(
        name: 'Chew Toy',
        price: '\$9.99',
        imageUrl: 'assets/images/logo.png',
        productUrl: null,
      ),
      Product(
        name: 'Leash',
        price: '\$15.00',
        imageUrl: 'assets/images/logo.png',
        productUrl: null,
      ),
      Product(
        name: 'Pet Bed',
        price: '\$45.00',
        imageUrl: 'assets/images/logo.png',
        productUrl: null,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        return ProductCard(product: _filteredProducts[index]);
      },
    );
  }
}

class Product {
  final String name;
  final String price;
  final String imageUrl;
  final String? productUrl;

  Product({required this.name, required this.price, required this.imageUrl, this.productUrl});
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  Future<void> _launchUrl() async {
    if (product.productUrl != null) {
      final Uri url = Uri.parse(product.productUrl!); 
      if (!await launchUrl(url)) {
        throw Exception('Could not launch ${url}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: product.productUrl != null ? _launchUrl : null,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Image.asset(product.imageUrl, width: 100, height: 100),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(product.price, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
