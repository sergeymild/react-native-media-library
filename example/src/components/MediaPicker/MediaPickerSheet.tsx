import React, { useCallback, useEffect, useRef, useState } from 'react';
import { StyleSheet, View, TouchableOpacity, Text, Dimensions } from 'react-native';
import {
  FittedSheet,
  type FittedSheetRef,
  attachScrollViewToFittedSheet,
} from 'react-native-sheet';
import {
  mediaLibrary,
  type AssetItem,
  type CollectionItem,
} from 'react-native-media-library';
import { AlbumSelector } from './AlbumSelector';
import { PhotoGrid } from './PhotoGrid';

const { height: SCREEN_HEIGHT } = Dimensions.get('window');

interface MediaPickerSheetProps {
  visible: boolean;
  onClose: () => void;
  onSelectMedia: (items: AssetItem[]) => void;
  multiSelect?: boolean;
  maxSelect?: number;
  mediaType?: ('photo' | 'video')[];
}

export const MediaPickerSheet: React.FC<MediaPickerSheetProps> = ({
  visible,
  onClose,
  onSelectMedia,
  multiSelect = true,
  maxSelect = 10,
  mediaType = ['photo', 'video'],
}) => {
  const sheetRef = useRef<FittedSheetRef>(null);

  const [collections, setCollections] = useState<CollectionItem[]>([]);
  const [selectedCollection, setSelectedCollection] =
    useState<CollectionItem | null>(null);
  const [assets, setAssets] = useState<AssetItem[]>([]);
  const [selectedAssets, setSelectedAssets] = useState<AssetItem[]>([]);
  const [loading, setLoading] = useState(false);
  const offsetRef = useRef(0);

  // Show/hide sheet based on visible prop
  useEffect(() => {
    if (visible) {
      sheetRef.current?.show();
    } else {
      sheetRef.current?.hide();
    }
  }, [visible]);

  // Load collections on mount
  useEffect(() => {
    if (visible) {
      loadCollections();
    }
  }, [visible]);

  // Load assets when collection changes
  useEffect(() => {
    if (visible) {
      loadAssets(true);
    }
  }, [selectedCollection, visible]);

  const loadCollections = async () => {
    try {
      const cols = await mediaLibrary.getCollections();
      const allPhotos: CollectionItem = {
        id: '',
        filename: 'All Photos',
        count: 0,
      };
      setCollections([allPhotos, ...cols]);
      setSelectedCollection(allPhotos);
    } catch (e) {
      console.error('Failed to load collections:', e);
    }
  };

  const loadAssets = async (reset = false) => {
    if (loading) return;
    setLoading(true);

    try {
      const newOffset = reset ? 0 : offsetRef.current;
      const result = await mediaLibrary.getAssets({
        mediaType,
        limit: 50,
        offset: newOffset,
        collectionId: selectedCollection?.id || undefined,
        sortBy: 'creationTime',
        sortOrder: 'desc',
      });

      if (reset) {
        setAssets(result);
        offsetRef.current = result.length;
      } else {
        setAssets((prev) => [...prev, ...result]);
        offsetRef.current += result.length;
      }
    } catch (e) {
      console.error('Failed to load assets:', e);
    } finally {
      setLoading(false);
    }
  };

  const handleClose = useCallback(() => {
    onClose();
    setSelectedAssets([]);
  }, [onClose]);

  const handleSelectAsset = (asset: AssetItem) => {
    if (multiSelect) {
      setSelectedAssets((prev) => {
        const isSelected = prev.some((a) => a.id === asset.id);
        if (isSelected) {
          return prev.filter((a) => a.id !== asset.id);
        }
        if (prev.length >= maxSelect) {
          return prev;
        }
        return [...prev, asset];
      });
    } else {
      onSelectMedia([asset]);
      handleClose();
    }
  };

  const handleDone = () => {
    onSelectMedia(selectedAssets);
    handleClose();
  };

  return (
    <FittedSheet
      ref={sheetRef}
      params={{
        minHeight: SCREEN_HEIGHT * 0.5,
        maxHeight: SCREEN_HEIGHT - 50,
        backgroundColor: '#1c1c1e',
        topLeftRightCornerRadius: 24,
        dismissable: true,
        grabberVisible: true,
        grabberColor: '#5c5c5e',
      }}
      onSheetDismiss={handleClose}
    >
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={handleClose} style={styles.headerButton}>
          <Text style={styles.headerButtonText}>Cancel</Text>
        </TouchableOpacity>

        <AlbumSelector
          collections={collections}
          selected={selectedCollection}
          onSelect={setSelectedCollection}
        />

        {multiSelect && selectedAssets.length > 0 ? (
          <TouchableOpacity onPress={handleDone} style={styles.headerButton}>
            <Text style={[styles.headerButtonText, styles.doneText]}>
              Done ({selectedAssets.length})
            </Text>
          </TouchableOpacity>
        ) : (
          <View style={styles.headerButton} />
        )}
      </View>

      {/* Photo Grid */}
      <PhotoGrid
        assets={assets}
        selectedAssets={selectedAssets}
        onSelectAsset={handleSelectAsset}
        onEndReached={() => loadAssets(false)}
        multiSelect={multiSelect}
        onLayout={() => attachScrollViewToFittedSheet(sheetRef)}
      />
    </FittedSheet>
  );
};

const styles = StyleSheet.create({
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#3c3c3e',
  },
  headerButton: {
    width: 80,
  },
  headerButtonText: {
    color: '#0a84ff',
    fontSize: 17,
  },
  doneText: {
    fontWeight: '600',
    textAlign: 'right',
  },
});