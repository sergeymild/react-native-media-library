import React, { useState } from 'react';
import {
  StyleSheet,
  View,
  TouchableOpacity,
  Text,
  ScrollView,
  Dimensions,
} from 'react-native';
import FastImage from '@d11/react-native-fast-image';
import type { AssetItem } from 'react-native-media-library';
import { MediaPickerSheet } from '../../components/MediaPicker';

const { width: SCREEN_WIDTH } = Dimensions.get('window');
const PREVIEW_SIZE = (SCREEN_WIDTH - 48) / 3;

export const MediaPickerExample: React.FC = () => {
  const [pickerVisible, setPickerVisible] = useState(false);
  const [selectedMedia, setSelectedMedia] = useState<AssetItem[]>([]);

  const handleSelectMedia = (items: AssetItem[]) => {
    setSelectedMedia(items);
    console.log('Selected media:', items);
  };

  const handleRemoveItem = (id: string) => {
    setSelectedMedia((prev) => prev.filter((item) => item.id !== id));
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Media Picker Example</Text>
      <Text style={styles.subtitle}>Telegram-style bottom sheet picker</Text>

      {/* Selected Media Preview */}
      {selectedMedia.length > 0 && (
        <View style={styles.previewSection}>
          <Text style={styles.sectionTitle}>
            Selected ({selectedMedia.length})
          </Text>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.previewScroll}
          >
            {selectedMedia.map((item) => (
              <View key={item.id} style={styles.previewItem}>
                <FastImage
                  source={{ uri: item.uri }}
                  style={styles.previewImage}
                  resizeMode={FastImage.resizeMode.cover}
                  resizeSize={{ width: PREVIEW_SIZE, height: PREVIEW_SIZE }}
                />
                <TouchableOpacity
                  style={styles.removeButton}
                  onPress={() => handleRemoveItem(item.id)}
                >
                  <Text style={styles.removeButtonText}>×</Text>
                </TouchableOpacity>
                {item.mediaType === 'video' && (
                  <View style={styles.videoBadge}>
                    <Text style={styles.videoBadgeText}>
                      {formatDuration(item.duration)}
                    </Text>
                  </View>
                )}
              </View>
            ))}
          </ScrollView>
        </View>
      )}

      {/* Open Picker Button */}
      <TouchableOpacity
        style={styles.openButton}
        onPress={() => setPickerVisible(true)}
      >
        <Text style={styles.openButtonText}>Open Media Picker</Text>
      </TouchableOpacity>

      {/* Options */}
      <View style={styles.infoSection}>
        <Text style={styles.infoTitle}>Features:</Text>
        <Text style={styles.infoText}>• Drag to expand/collapse</Text>
        <Text style={styles.infoText}>• Album switching</Text>
        <Text style={styles.infoText}>• Multi-select with order</Text>
        <Text style={styles.infoText}>• Video duration display</Text>
        <Text style={styles.infoText}>• Infinite scroll</Text>
      </View>

      {/* Media Picker Sheet */}
      <MediaPickerSheet
        visible={pickerVisible}
        onClose={() => setPickerVisible(false)}
        onSelectMedia={handleSelectMedia}
        multiSelect={true}
        maxSelect={10}
        mediaType={['photo', 'video']}
      />
    </View>
  );
};

const formatDuration = (seconds: number): string => {
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins}:${secs.toString().padStart(2, '0')}`;
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
    padding: 16,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: 'white',
    marginTop: 20,
  },
  subtitle: {
    fontSize: 16,
    color: '#8e8e93',
    marginTop: 8,
    marginBottom: 24,
  },
  previewSection: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 17,
    fontWeight: '600',
    color: 'white',
    marginBottom: 12,
  },
  previewScroll: {
    paddingRight: 16,
  },
  previewItem: {
    width: PREVIEW_SIZE,
    height: PREVIEW_SIZE,
    marginRight: 8,
    borderRadius: 8,
    overflow: 'hidden',
  },
  previewImage: {
    width: '100%',
    height: '100%',
    backgroundColor: '#2c2c2e',
  },
  removeButton: {
    position: 'absolute',
    top: 4,
    right: 4,
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  removeButtonText: {
    color: 'white',
    fontSize: 18,
    fontWeight: '600',
    marginTop: -2,
  },
  videoBadge: {
    position: 'absolute',
    bottom: 4,
    left: 4,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  videoBadgeText: {
    color: 'white',
    fontSize: 11,
    fontWeight: '500',
  },
  openButton: {
    backgroundColor: '#0a84ff',
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
    marginBottom: 24,
  },
  openButtonText: {
    color: 'white',
    fontSize: 17,
    fontWeight: '600',
  },
  infoSection: {
    backgroundColor: '#1c1c1e',
    borderRadius: 12,
    padding: 16,
  },
  infoTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: 'white',
    marginBottom: 12,
  },
  infoText: {
    fontSize: 14,
    color: '#8e8e93',
    marginBottom: 6,
  },
});