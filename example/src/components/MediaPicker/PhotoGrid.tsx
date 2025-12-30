import React, { useCallback } from 'react';
import {
  StyleSheet,
  View,
  TouchableOpacity,
  Text,
  FlatList,
  Dimensions,
} from 'react-native';
import FastImage from '@d11/react-native-fast-image';
import type { AssetItem } from 'react-native-media-library';

const { width: SCREEN_WIDTH } = Dimensions.get('window');
const NUM_COLUMNS = 3;
const ITEM_SPACING = 2;
const ITEM_SIZE =
  (SCREEN_WIDTH - ITEM_SPACING * (NUM_COLUMNS + 1)) / NUM_COLUMNS;

interface PhotoGridProps {
  assets: AssetItem[];
  selectedAssets: AssetItem[];
  onSelectAsset: (asset: AssetItem) => void;
  onEndReached: () => void;
  multiSelect: boolean;
  onLayout?: () => void;
}

export const PhotoGrid: React.FC<PhotoGridProps> = ({
  assets,
  selectedAssets,
  onSelectAsset,
  onEndReached,
  multiSelect,
  onLayout,
}) => {
  const getSelectionIndex = useCallback(
    (asset: AssetItem) => {
      const index = selectedAssets.findIndex((a) => a.id === asset.id);
      return index >= 0 ? index + 1 : -1;
    },
    [selectedAssets]
  );

  const renderItem = useCallback(
    ({ item }: { item: AssetItem }) => {
      const selectionIndex = getSelectionIndex(item);
      const isSelected = selectionIndex > 0;
      const isVideo = item.mediaType === 'video';

      return (
        <TouchableOpacity
          style={styles.itemContainer}
          onPress={() => onSelectAsset(item)}
          activeOpacity={0.8}
        >
          <FastImage
            source={{ uri: item.uri }}
            style={styles.image}
            resizeMode={FastImage.resizeMode.cover}
            resizeSize={{ width: ITEM_SIZE, height: ITEM_SIZE }}
          />

          {/* Video duration badge */}
          {isVideo && item.duration > 0 && (
            <View style={styles.durationBadge}>
              <Text style={styles.durationText}>
                {formatDuration(item.duration)}
              </Text>
            </View>
          )}

          {/* Selection indicator */}
          {multiSelect && (
            <View
              style={[
                styles.selectionCircle,
                isSelected && styles.selectionCircleSelected,
              ]}
            >
              {isSelected && (
                <Text style={styles.selectionNumber}>{selectionIndex}</Text>
              )}
            </View>
          )}

          {/* Selection overlay */}
          {isSelected && <View style={styles.selectedOverlay} />}
        </TouchableOpacity>
      );
    },
    [multiSelect, onSelectAsset, getSelectionIndex]
  );

  const keyExtractor = useCallback((item: AssetItem) => item.id, []);

  const getItemLayout = useCallback(
    (_: any, index: number) => ({
      length: ITEM_SIZE + ITEM_SPACING,
      offset: (ITEM_SIZE + ITEM_SPACING) * Math.floor(index / NUM_COLUMNS),
      index,
    }),
    []
  );

  return (
    <FlatList
      data={assets}
      renderItem={renderItem}
      keyExtractor={keyExtractor}
      numColumns={NUM_COLUMNS}
      getItemLayout={getItemLayout}
      onEndReached={onEndReached}
      onEndReachedThreshold={0.5}
      showsVerticalScrollIndicator={false}
      contentContainerStyle={styles.listContent}
      initialNumToRender={30}
      maxToRenderPerBatch={30}
      windowSize={10}
      onLayout={onLayout}
    />
  );
};

const formatDuration = (seconds: number): string => {
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins}:${secs.toString().padStart(2, '0')}`;
};

const styles = StyleSheet.create({
  listContent: {
    paddingHorizontal: ITEM_SPACING,
    paddingTop: ITEM_SPACING,
    flexGrow: 1,
  },
  itemContainer: {
    width: ITEM_SIZE,
    height: ITEM_SIZE,
    marginBottom: ITEM_SPACING,
    marginRight: ITEM_SPACING,
  },
  image: {
    width: '100%',
    height: '100%',
    backgroundColor: '#2c2c2e',
  },
  durationBadge: {
    position: 'absolute',
    bottom: 4,
    right: 4,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  durationText: {
    color: 'white',
    fontSize: 12,
    fontWeight: '500',
  },
  selectionCircle: {
    position: 'absolute',
    top: 6,
    right: 6,
    width: 24,
    height: 24,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: 'white',
    backgroundColor: 'rgba(0, 0, 0, 0.3)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  selectionCircleSelected: {
    backgroundColor: '#0a84ff',
    borderColor: '#0a84ff',
  },
  selectionNumber: {
    color: 'white',
    fontSize: 14,
    fontWeight: '600',
  },
  selectedOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(10, 132, 255, 0.2)',
    borderWidth: 3,
    borderColor: '#0a84ff',
  },
});