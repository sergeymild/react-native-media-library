import React, { useState } from 'react';
import {
  StyleSheet,
  View,
  TouchableOpacity,
  Text,
  Modal,
  FlatList,
  Dimensions,
} from 'react-native';
import type { CollectionItem } from 'react-native-media-library';

interface AlbumSelectorProps {
  collections: CollectionItem[];
  selected: CollectionItem | null;
  onSelect: (collection: CollectionItem) => void;
}

export const AlbumSelector: React.FC<AlbumSelectorProps> = ({
  collections,
  selected,
  onSelect,
}) => {
  const [dropdownVisible, setDropdownVisible] = useState(false);

  const handleSelect = (collection: CollectionItem) => {
    onSelect(collection);
    setDropdownVisible(false);
  };

  return (
    <View>
      <TouchableOpacity
        style={styles.selector}
        onPress={() => setDropdownVisible(true)}
      >
        <Text style={styles.selectorText} numberOfLines={1}>
          {selected?.filename || 'All Photos'}
        </Text>
        <Text style={styles.arrow}>▼</Text>
      </TouchableOpacity>

      <Modal
        visible={dropdownVisible}
        transparent
        animationType="fade"
        onRequestClose={() => setDropdownVisible(false)}
      >
        <TouchableOpacity
          style={styles.modalBackdrop}
          activeOpacity={1}
          onPress={() => setDropdownVisible(false)}
        >
          <View style={styles.dropdown}>
            <View style={styles.dropdownHeader}>
              <Text style={styles.dropdownTitle}>Albums</Text>
            </View>
            <FlatList
              data={collections}
              keyExtractor={(item) => item.id || 'all'}
              renderItem={({ item }) => (
                <TouchableOpacity
                  style={[
                    styles.dropdownItem,
                    selected?.id === item.id && styles.dropdownItemSelected,
                  ]}
                  onPress={() => handleSelect(item)}
                >
                  <Text
                    style={[
                      styles.dropdownItemText,
                      selected?.id === item.id &&
                        styles.dropdownItemTextSelected,
                    ]}
                    numberOfLines={1}
                  >
                    {item.filename}
                  </Text>
                  {item.count > 0 && (
                    <Text style={styles.dropdownItemCount}>{item.count}</Text>
                  )}
                  {selected?.id === item.id && (
                    <Text style={styles.checkmark}>✓</Text>
                  )}
                </TouchableOpacity>
              )}
              style={styles.dropdownList}
            />
          </View>
        </TouchableOpacity>
      </Modal>
    </View>
  );
};

const { width: SCREEN_WIDTH } = Dimensions.get('window');

const styles = StyleSheet.create({
  selector: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: '#2c2c2e',
    borderRadius: 8,
    maxWidth: SCREEN_WIDTH * 0.4,
  },
  selectorText: {
    color: 'white',
    fontSize: 15,
    fontWeight: '600',
    marginRight: 6,
    flexShrink: 1,
  },
  arrow: {
    color: '#8e8e93',
    fontSize: 10,
  },
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  dropdown: {
    backgroundColor: '#2c2c2e',
    borderRadius: 14,
    width: SCREEN_WIDTH * 0.8,
    maxHeight: 400,
    overflow: 'hidden',
  },
  dropdownHeader: {
    paddingVertical: 16,
    paddingHorizontal: 20,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#3c3c3e',
  },
  dropdownTitle: {
    color: 'white',
    fontSize: 17,
    fontWeight: '600',
    textAlign: 'center',
  },
  dropdownList: {
    maxHeight: 340,
  },
  dropdownItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 14,
    paddingHorizontal: 20,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#3c3c3e',
  },
  dropdownItemSelected: {
    backgroundColor: '#3a3a3c',
  },
  dropdownItemText: {
    color: 'white',
    fontSize: 17,
    flex: 1,
  },
  dropdownItemTextSelected: {
    color: '#0a84ff',
  },
  dropdownItemCount: {
    color: '#8e8e93',
    fontSize: 15,
    marginRight: 10,
  },
  checkmark: {
    color: '#0a84ff',
    fontSize: 17,
    fontWeight: '600',
  },
});