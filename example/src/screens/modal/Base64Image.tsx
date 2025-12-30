import React, { useState } from 'react';
import { Image, Text, TextInput, TouchableOpacity, View } from 'react-native';
import { mediaLibrary } from 'react-native-media-library';

export const Base64Image: React.FC = () => {
  const [url, setUrl] = useState(
    'https://fastly.picsum.photos/id/4/200/300.jpg?hmac=y6_DgDO4ccUuOHUJcEWirdjxlpPwMcEZo7fz1MpuaWg'
  );

  const [image, setImage] = useState<string | undefined>();

  return (
    <View style={{ flex: 1 }}>
      <TouchableOpacity
        onPress={async () => {
          if (url.length === 0) return;
          const response = await mediaLibrary.downloadAsBase64({ url: url });
          setImage(response?.base64);
        }}
      >
        <Text children={'Download and convert'} />
      </TouchableOpacity>

      <TextInput
        value={url}
        onChangeText={setUrl}
        placeholder={'url to download'}
      />

      <Image
        source={{ uri: `data:image/png;base64,${image}` }}
        style={{ width: 100, height: 100, resizeMode: 'center' }}
      />
    </View>
  );
};
