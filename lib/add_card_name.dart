import 'dart:io';
import 'package:LoyaltyWallet/models/store.dart';
import 'package:LoyaltyWallet/navbar.dart';
import 'package:LoyaltyWallet/providers/account_provider.dart';
import 'package:LoyaltyWallet/providers/fidelity_cards_provider.dart';
import 'package:LoyaltyWallet/providers/stores_provider.dart';
import 'package:LoyaltyWallet/providers/theme_provider.dart';
import 'package:LoyaltyWallet/utils/url.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';

class AddCardName extends StatefulWidget {
  final String barcode;
  final String format;

  const AddCardName({
    required this.barcode,
    required this.format,
    super.key,
  });

  @override
  State<AddCardName> createState() => _AddCardNameState();
}

class _AddCardNameState extends State<AddCardName> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customNameController = TextEditingController();
  List<Store> filteredStores = [];
  List<Store> rawStores = []; // List to store all store names initially
  String selectedStoreID = '';
  bool isLoading = false; // To show loading state while stores load
  bool showCustomImageOption = false; // To show custom image option
  bool isUsingCustomImage = false; // To track if user is using custom image
  String customImageURL = ''; // URL for custom image

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      _filterStores();
      setState(() {
        // Show custom image option only when user has typed something
        showCustomImageOption = _searchController.text.isNotEmpty;
      });
    });

    // Load stores from the provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cards = Provider.of<FidelityCardsProvider>(context, listen: false);
      final stores = Provider.of<StoresProvider>(context, listen: false);

      await cards.addCardAttachBarcode(widget.barcode, widget.format);
      setState(() {
        rawStores = stores.rawStores;
        // filteredStores = stores.rawStores;
      });
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterStores);
    _searchController.dispose();
    _customNameController.dispose();
    super.dispose();
  }

  // Filters the stores based on user input
  void _filterStores() {
    setState(() {
      if (_searchController.text.isEmpty) {
        filteredStores = []; // Empty list if no characters are typed
        showCustomImageOption = false;
      } else {
        filteredStores = rawStores
            .where((store) => store.name
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
            .toList();
        showCustomImageOption = true;
      }
    });
  }

  // Show dialog to enter custom image URL
  void _showCustomImageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Custom Card Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _customNameController,
              decoration: InputDecoration(
                labelText: 'Card Name',
                hintText: 'Enter card/store name',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Image URL (Optional)',
                hintText: 'Enter image URL or leave empty',
              ),
              onChanged: (value) {
                setState(() {
                  customImageURL = value;
                });
              },
            ),
            SizedBox(height: 16),
            Text(
              'Note: You can enter a direct image URL or continue without an image.',
              style: TextStyle(
                fontSize: 12, 
                color: Colors.grey
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                isUsingCustomImage = true;
                selectedStoreID = 'custom';
                // Use the custom name for search text if provided
                if (_customNameController.text.isNotEmpty) {
                  _searchController.text = _customNameController.text;
                }
              });
              Navigator.pop(context);
            },
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios_new),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).shadowColor,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Icon(
                    CupertinoIcons.textformat_abc_dottedunderline,
                    size: 30,
                    color: Color.fromARGB(255, 76, 76, 76),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                AppLocalizations.of(context)!.card_name_title,
                style: const TextStyle(
                  fontSize: 22,
                  fontFamily: 'SFProRounded',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                AppLocalizations.of(context)!.card_name_description,
                style: const TextStyle(
                  fontSize: 15,
                  fontFamily: 'SFProRounded',
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 10, top: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      keyboardType: TextInputType.name,
                      controller: _searchController,
                      textInputAction: TextInputAction.done,
                      cursorColor: Colors.black,
                      style: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'UberMoveMedium',
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: Theme.of(context).shadowColor,
                        filled: true,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Custom image option
              if (showCustomImageOption)
                GestureDetector(
                  onTap: () {
                    _showCustomImageDialog();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isUsingCustomImage 
                          ? Theme.of(context).primaryColor.withOpacity(0.2)
                          : Theme.of(context).shadowColor,
                    ),
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.17,
                          height: MediaQuery.of(context).size.width * 0.17 / 1.586,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[300],
                          ),
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 24,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "Add Custom Card",
                          style: TextStyle(
                            fontFamily: "SFProDisplay",
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              Expanded(
                child: isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator()) // Show a loading indicator
                    : Consumer<AccountProvider>(builder: (context, auth, _) {
                        return Consumer<FidelityCardsProvider>(
                            builder: (context, cards, _) {
                          return Consumer<StoresProvider>(
                            builder: (context, stores, _) {
                              return Consumer<ThemeProvider>(
                                  builder: (context, themeProvider, _) {
                                return ListView.builder(
                                  itemCount: filteredStores.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedStoreID =
                                              filteredStores[index].id;
                                          isUsingCustomImage = false;
                                        });
                                      },
                                      child: DecoratedBox(
                                        decoration: filteredStores[index].id ==
                                                selectedStoreID
                                            ? BoxDecoration(
                                                color: themeProvider
                                                    .themeData.shadowColor,
                                                borderRadius:
                                                    BorderRadius.circular(12))
                                            : const BoxDecoration(),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10.0, vertical: 10),
                                          child: Row(children: [
                                            Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.17,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.17 /
                                                  1.586,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                image: DecorationImage(
                                                    image:
                                                        CachedNetworkImageProvider(
                                                  getStoreImage(
                                                      filteredStores[index].id),
                                                )),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              filteredStores[index].name,
                                              style: const TextStyle(
                                                  fontFamily: "SFProDisplay",
                                                  fontSize: 16),
                                            ),
                                          ]),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              });
                            },
                          );
                        });
                      }),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: GestureDetector(
          onTap: () async {
            final cards =
                Provider.of<FidelityCardsProvider>(context, listen: false);
            final auth = Provider.of<AccountProvider>(context, listen: false);

            if (isUsingCustomImage) {
              // Using custom card
              cards.addCardAttachCustomStore(
                _customNameController.text.isNotEmpty 
                    ? _customNameController.text 
                    : _searchController.text,
                customImageURL
              );
            } else if (selectedStoreID.isNotEmpty) {
              // Using existing store
              cards.addCardAttachStore(selectedStoreID);
            } else {
              // No store selected
              return;
            }

            cards.addCardAttachNickname('');
            await cards.addFidelityCard(auth.token);

            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const NavBar(pageIndex: 0)),
              (route) => false,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
            child: Padding(
              padding: EdgeInsets.only(bottom: kIsWeb ? 0 : (Platform.isAndroid ? 15 : 0)),
              child: Container(
                decoration: BoxDecoration(
                  color: (selectedStoreID.isNotEmpty || isUsingCustomImage)
                      ? const Color.fromARGB(255, 3, 68, 230)
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.continue_button,
                        style: const TextStyle(
                          fontFamily: "SFProDisplay",
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
