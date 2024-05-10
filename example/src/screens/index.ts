export const screens = [
  {
    title: 'Media',
    data: [
      {
        name: 'CollectionsList',
        slug: 'CollectionsList',
        getScreen: () => require('./modal/CollectionsList').CollectionsList,
      },
      {
        name: 'ImagesList',
        slug: 'ImagesList',
        getScreen: () => require('./modal/ImagesList').ImagesList,
      },
      {
        name: 'SloMo',
        slug: 'SloMo',
        getScreen: () => require('./modal/SloMo').SloMo,
      },
      {
        name: 'ExportVideo',
        slug: 'ExportVideo',
        getScreen: () => require('./modal/ExportVideo').ExportVideo,
      },
      {
        name: 'Base64Image',
        slug: 'Base64Image',
        getScreen: () => require('./modal/Base64Image').Base64Image,
      },
      {
        name: 'CombineImages',
        slug: 'CombineImages',
        getScreen: () => require('./modal/CombineImages').CombineImages,
      },
    ],
  },
];
