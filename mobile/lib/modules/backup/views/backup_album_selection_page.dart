import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/immich_colors.dart';
import 'package:immich_mobile/modules/backup/providers/backup.provider.dart';
import 'package:immich_mobile/modules/backup/ui/album_info_card.dart';
import 'package:immich_mobile/modules/backup/ui/album_info_list_tile.dart';
import 'package:immich_mobile/shared/ui/immich_loading_indicator.dart';
import 'package:immich_mobile/shared/ui/immich_toast.dart';

class BackupAlbumSelectionPage extends HookConsumerWidget {
  const BackupAlbumSelectionPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final availableAlbums = ref.watch(backupProvider).availableAlbums;
    final selectedBackupAlbums = ref.watch(backupProvider).selectedBackupAlbums;
    final excludedBackupAlbums = ref.watch(backupProvider).excludedBackupAlbums;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final allAlbums = ref.watch(backupProvider).availableAlbums;

    // Albums which are displayed to the user
    // by filtering out based on search
    final filteredAlbums = useState(allAlbums);
    final albums = filteredAlbums.value;

    useEffect(
      () {
        ref.watch(backupProvider.notifier).getBackupInfo();
        return null;
      },
      [],
    );

    buildAlbumSelectionList() {
      if (albums.isEmpty) {
        return const SliverToBoxAdapter(
          child: Center(
            child: ImmichLoadingIndicator(),
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            ((context, index) {
              var thumbnailData = albums[index].thumbnailData;
              return AlbumInfoListTile(
                imageData: thumbnailData,
                albumInfo: albums[index],
              );
            }),
            childCount: albums.length,
          ),
        ),
      );
    }

    buildAlbumSelectionGrid() {
      if (albums.isEmpty) {
        return const SliverToBoxAdapter(
          child: Center(
            child: ImmichLoadingIndicator(),
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.all(12.0),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: albums.length,
          itemBuilder: ((context, index) {
            var thumbnailData = albums[index].thumbnailData;
            return AlbumInfoCard(
              imageData: thumbnailData,
              albumInfo: albums[index],
            );
          }),
        ),
      );
    }

    buildSelectedAlbumNameChip() {
      return selectedBackupAlbums.map((album) {
        void removeSelection() {
          if (ref.watch(backupProvider).selectedBackupAlbums.length == 1) {
            ImmichToast.show(
              context: context,
              msg: "backup_err_only_album".tr(),
              toastType: ToastType.error,
              gravity: ToastGravity.BOTTOM,
            );
            return;
          }

          ref.watch(backupProvider.notifier).removeAlbumForBackup(album);
        }

        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: GestureDetector(
            onTap: removeSelection,
            child: Chip(
              label: Text(
                album.name,
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkTheme ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Theme.of(context).primaryColor,
              deleteIconColor: isDarkTheme ? Colors.black : Colors.white,
              deleteIcon: const Icon(
                Icons.cancel_rounded,
                size: 15,
              ),
              onDeleted: removeSelection,
            ),
          ),
        );
      }).toSet();
    }

    buildExcludedAlbumNameChip() {
      return excludedBackupAlbums.map((album) {
        void removeSelection() {
          ref
              .watch(backupProvider.notifier)
              .removeExcludedAlbumForBackup(album);
        }

        return GestureDetector(
          onTap: removeSelection,
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Chip(
              label: Text(
                album.name,
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkTheme ? Colors.black : immichBackgroundColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.red[300],
              deleteIconColor:
                  isDarkTheme ? Colors.black : immichBackgroundColor,
              deleteIcon: const Icon(
                Icons.cancel_rounded,
                size: 15,
              ),
              onDeleted: removeSelection,
            ),
          ),
        );
      }).toSet();
    }

    buildSearchBar() {
      return Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16, bottom: 8.0),
        child: TextFormField(
          onChanged: (searchValue) {
            if (searchValue.isEmpty) {
              filteredAlbums.value = allAlbums;
            } else {
              filteredAlbums.value = allAlbums
                  .where(
                    (album) => album.name
                        .toLowerCase()
                        .contains(searchValue.toLowerCase()),
                  )
                  .toList();
            }
          },
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 8.0,
            ),
            hintText: "Search",
            hintStyle: TextStyle(
              color: isDarkTheme ? Colors.white : Colors.grey,
              fontSize: 14.0,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: Colors.grey,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: isDarkTheme ? Colors.white30 : Colors.grey[200],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => AutoRouter.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
        title: const Text(
          "backup_album_selection_page_select_albums",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ).tr(),
        elevation: 0,
      ),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: const Text(
                    "backup_album_selection_page_selection_info",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ).tr(),
                ),
                // Selected Album Chips

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Wrap(
                    children: [
                      ...buildSelectedAlbumNameChip(),
                      ...buildExcludedAlbumNameChip(),
                    ],
                  ),
                ),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Card(
                    margin: const EdgeInsets.all(0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isDarkTheme
                            ? const Color.fromARGB(255, 0, 0, 0)
                            : const Color.fromARGB(255, 235, 235, 235),
                        width: 1,
                      ),
                    ),
                    elevation: 0,
                    borderOnForeground: false,
                    child: Column(
                      children: [
                        ListTile(
                          visualDensity: VisualDensity.compact,
                          title: const Text(
                            "backup_album_selection_page_total_assets",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ).tr(),
                          trailing: Text(
                            ref
                                .watch(backupProvider)
                                .allUniqueAssets
                                .length
                                .toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                ListTile(
                  title: Text(
                    "backup_album_selection_page_albums_device".tr(
                      args: [
                        ref
                            .watch(backupProvider)
                            .availableAlbums
                            .length
                            .toString(),
                      ],
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "backup_album_selection_page_albums_tap",
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ).tr(),
                  ),
                  trailing: IconButton(
                    splashRadius: 16,
                    icon: Icon(
                      Icons.info,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      // show the dialog
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 5,
                            title: Text(
                              'backup_album_selection_page_selection_info',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ).tr(),
                            content: SingleChildScrollView(
                              child: ListBody(
                                children: [
                                  const Text(
                                    'backup_album_selection_page_assets_scatter',
                                    style: TextStyle(
                                      fontSize: 14,
                                    ),
                                  ).tr(),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                buildSearchBar(),
              ],
            ),
          ),
          SliverLayoutBuilder(
            builder: (context, constraints) {
              if (constraints.crossAxisExtent > 600) {
                return buildAlbumSelectionGrid();
              } else {
                return buildAlbumSelectionList();
              }
            },
          ),
        ],
      ),
    );
  }
}
