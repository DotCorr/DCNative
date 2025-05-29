import 'package:dcf_primitives/dcf_primitives.dart';
import 'package:dcflight/dcflight.dart';
import '../store/store.dart';

class ImagePickerModal extends StatefulComponent {
  final Function(String) onImageSelected;

  ImagePickerModal({required this.onImageSelected});

  @override
  DCFComponentNode render() {
    final selectedCategory = useState("abstract");
    
    final categories = [
      {"id": "abstract", "name": "Abstract", "icon": DCFIcons.palette},
      {"id": "nature", "name": "Nature", "icon": DCFIcons.leaf},
      {"id": "city", "name": "City", "icon": DCFIcons.building},
      {"id": "people", "name": "People", "icon": DCFIcons.user},
      {"id": "tech", "name": "Tech", "icon": DCFIcons.monitor},
      {"id": "art", "name": "Art", "icon": DCFIcons.paintBucket},
    ];

    final images = _getImagesForCategory(selectedCategory.state);

    return DCFView(
      layout: LayoutProps(
        flex: 1,
        alignItems: YogaAlign.center,
        justifyContent: YogaJustifyContent.center,
        padding: 20,
      ),
      children: [
        DCFView(
          layout: LayoutProps(
            width: "100%",
            height: "80%",
            padding: 24,
          ),
          style: StyleSheet(
            backgroundColor: Colors.white,
            borderRadius: 16,
            shadowColor: Colors.black.withOpacity(0.2),
            shadowRadius: 12,
            shadowOffsetY: 4,
          ),
          children: [
            // Header
            DCFView(
              layout: LayoutProps(
                flexDirection: YogaFlexDirection.row,
                justifyContent: YogaJustifyContent.spaceBetween,
                alignItems: YogaAlign.center,
                marginBottom: 24,
              ),
              children: [
                DCFText(
                  content: "Choose Avatar",
                  textProps: TextProps(
                    fontSize: 20,
                    fontWeight: "bold",
                    color: Colors.grey[900],
                  ),
                ),
                DCFTouchableOpacity(
                  onPress: (v) {
                    imagePickerModalStore.setState(false);
                  },
                  layout: LayoutProps(
                    width: 32,
                    height: 32,
                    alignItems: YogaAlign.center,
                    justifyContent: YogaJustifyContent.center,
                  ),
                  children: [
                    DCFIcon(
                      iconProps: IconProps(
                        name: DCFIcons.x,
                        color: Colors.grey[600],
                      ),
                      layout: LayoutProps(width: 20, height: 20),
                    ),
                  ],
                ),
              ],
            ),

            // Categories
            DCFScrollView(
              layout: LayoutProps(
                height: 60,
                marginBottom: 16,
              ),
              horizontal: true,
              showsScrollIndicator: false,
              children: categories.map((category) =>
                DCFTouchableOpacity(
                  onPress: (v) {
                    selectedCategory.setState(category["id"] as String);
                  },
                  layout: LayoutProps(
                    marginRight: 12,
                    paddingHorizontal: 16,
                    paddingVertical: 8,
                    flexDirection: YogaFlexDirection.row,
                    alignItems: YogaAlign.center,
                  ),
                  style: StyleSheet(
                    backgroundColor: selectedCategory.state == category["id"]
                        ? Colors.blue
                        : Colors.grey[100],
                    borderRadius: 20,
                  ),
                  children: [
                    DCFIcon(
                      iconProps: IconProps(
                        name: category["icon"] as String,
                        color: selectedCategory.state == category["id"]
                            ? Colors.white
                            : Colors.grey[600],
                      ),
                      layout: LayoutProps(width: 16, height: 16, marginRight: 8),
                    ),
                    DCFText(
                      content: category["name"] as String,
                      textProps: TextProps(
                        fontSize: 14,
                        fontWeight: "500",
                        color: selectedCategory.state == category["id"]
                            ? Colors.white
                            : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ).toList(),
            ),

            // Images grid
            DCFScrollView(
              layout: LayoutProps(flex: 1),
              showsScrollIndicator: false,
              children: [
                DCFView(
                  layout: LayoutProps(
                    flexDirection: YogaFlexDirection.row,
                    flexWrap: YogaWrap.wrap,
                    justifyContent: YogaJustifyContent.spaceBetween,
                  ),
                  children: images.map((imageUrl) =>
                    DCFTouchableOpacity(
                      onPress: (v) {
                        onImageSelected(imageUrl);
                      },
                      layout: LayoutProps(
                        width: "30%",
                        aspectRatio: 1,
                        marginBottom: 12,
                      ),
                      children: [
                        DCFView(
                          layout: LayoutProps(
                            width: "100%",
                            height: "100%",
                          ),
                          style: StyleSheet(
                            borderRadius: 8,
                            backgroundColor: Colors.grey[200],
                          ),
                          children: [
                            DCFImage(
                              imageProps: ImageProps(
                                source: imageUrl,
                                resizeMode: ImageResizeMode.cover,
                              ),
                              layout: LayoutProps(
                                width: "100%",
                                height: "100%",
                              ),
                              style: StyleSheet(
                                borderRadius: 8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).toList(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  List<String> _getImagesForCategory(String category) {
    final baseUrl = "https://picsum.photos/200/200";
    final categorySeeds = {
      "abstract": [1, 15, 30, 45, 60, 75, 90, 105, 120, 135, 150, 165],
      "nature": [2, 16, 31, 46, 61, 76, 91, 106, 121, 136, 151, 166],
      "city": [3, 17, 32, 47, 62, 77, 92, 107, 122, 137, 152, 167],
      "people": [4, 18, 33, 48, 63, 78, 93, 108, 123, 138, 153, 168],
      "tech": [5, 19, 34, 49, 64, 79, 94, 109, 124, 139, 154, 169],
      "art": [6, 20, 35, 50, 65, 80, 95, 110, 125, 140, 155, 170],
    };

    final seeds = categorySeeds[category] ?? categorySeeds["abstract"]!;
    return seeds.map((seed) => "$baseUrl?random=$seed").toList();
  }
}
