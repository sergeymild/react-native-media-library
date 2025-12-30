import React, { useState } from 'react';
import { Image, Text, TouchableOpacity, View } from 'react-native';
import { mediaLibrary } from 'react-native-media-library';

export const CombineImages: React.FC = () => {
  const [url] = useState(
    'https://fastly.picsum.photos/id/4/200/300.jpg?hmac=y6_DgDO4ccUuOHUJcEWirdjxlpPwMcEZo7fz1MpuaWg'
  );

  const [image, setImage] = useState<string | undefined>();
  const [render, setRender] = useState<number>(0);
  console.log('🍓[CombineImages.CombineImages]');

  return (
    <View style={{ flex: 1 }}>
      <TouchableOpacity
        onPress={async () => {
          const path = `file://${mediaLibrary.cacheDir}/combined.png`;
          console.log('🍓[CombineImages.]', path);
          const response = await mediaLibrary.combineImages({
            mainImageIndex: 0,
            images: [
              url,
              {
                image: require('../../../assets/tombstone.png'),
                positions: { x: 0, y: 0 },
              },
            ],
            resultSavePath: path,
          });
          console.log('🍓[CombineImages.]', response);
          setRender(Date.now);
          setImage(path);
        }}
      >
        <Text children={'Combine'} />
      </TouchableOpacity>

      <Image
        source={require('../../../assets/tombstone.png')}
        style={{ width: 40, height: 40 }}
      />

      <Image source={{ uri: url }} style={{ width: 40, height: 40 }} />

      <Image
        key={render}
        source={{ uri: image }}
        style={{ width: 200, height: 300, resizeMode: 'contain' }}
      />
    </View>
  );
};
