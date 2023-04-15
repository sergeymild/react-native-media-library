import React, { useEffect, useState } from 'react';
import {
  Dimensions,
  Image,
  Platform,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { AssetItem, mediaLibrary } from 'react-native-media-library';
import FastImage from 'react-native-fast-image';

export const CropImageExample: React.FC = () => {
  const [original, setOriginal] = useState<AssetItem | undefined>();
  const [cropped, setCropped] = useState<AssetItem | undefined>();
  const [x, setX] = useState('0');
  const [y, setY] = useState('0.9');
  const [w, setW] = useState('500');
  const [h, setH] = useState('500');

  useEffect(() => {
    mediaLibrary
      .getAssets({
        limit: 1,
        offset: 0,
        mediaType: ['photo'],
        sortBy: 'creationTime',
        sortOrder: 'desc',
      })
      .then((r) => {
        console.log('[CropImageExample.]', r[0]);
        setOriginal(r[0]);
      });
  }, []);

  const onCropPress = async () => {
    console.log(
      '[CropImageExample.onCropPress]',
      `${mediaLibrary.cacheDir}/resize.png`
    );
    const asset = await mediaLibrary.getAsset(original!.id);
    console.log('[CropImageExample.onCropPress]', asset?.url);
    const response = await mediaLibrary.imageCrop({
      resultSavePath: `${mediaLibrary.cacheDir}/resize.png`,
      uri: asset!.url,
      x: parseFloat(x),
      y: parseFloat(y),
      width: parseInt(w, 10),
      height: parseInt(h, 10),
    });
    setCropped({
      ...asset,
      uri:
        Platform.OS === 'ios'
          ? `${mediaLibrary.cacheDir}/resize.png`
          : `file://${mediaLibrary.cacheDir}/resize.png`,
    });
    console.log('[CropImageExample.onCropPress]', response);
  };

  return (
    <View>
      <View style={{ flexDirection: 'row' }}>
        {!!original && (
          <FastImage
            source={{ uri: original.uri }}
            style={{
              marginTop: 100,
              marginBottom: 100,
              width: Dimensions.get('window').width / 2,
              height:
                (Dimensions.get('window').width / 2) *
                (original.width / original.height),
            }}
          />
        )}
        {!!cropped && (
          <Image
            source={{ uri: cropped.uri }}
            style={{
              marginTop: 100,
              marginBottom: 100,
              width: Dimensions.get('window').width / 2,
              height:
                (Dimensions.get('window').width / 2) *
                (cropped.width / cropped.height),
            }}
          />
        )}
      </View>

      <View style={{ flexDirection: 'row' }}>
        <Text children={'X'} style={{ marginEnd: 16 }} />
        <TextInput value={x} onChangeText={setX} />
      </View>
      <View style={{ flexDirection: 'row', marginTop: 16 }}>
        <Text children={'Y'} style={{ marginEnd: 16 }} />
        <TextInput value={y} onChangeText={setY} />
      </View>
      <View style={{ flexDirection: 'row', marginTop: 16 }}>
        <Text children={'W'} style={{ marginEnd: 16 }} />
        <TextInput value={w} onChangeText={setW} />
      </View>
      <View style={{ flexDirection: 'row', marginTop: 16 }}>
        <Text children={'H'} style={{ marginEnd: 16 }} />
        <TextInput value={h} onChangeText={setH} />
      </View>

      <TouchableOpacity onPress={onCropPress} style={{ marginTop: 16 }}>
        <Text children={'Crop'} />
      </TouchableOpacity>
    </View>
  );
};
