//
//  MediaAssetFileNative.hpp
//  react-native-media-library
//
//  Created by Sergei Golishnikov on 19/04/2024.
//


#ifndef MediaAssetFileNative_h
#define MediaAssetFileNative_h

#include <dirent.h>
#include <sys/stat.h>
#include <string.h>
#include <libgen.h>
#include <vector>

namespace MediaAssetFileNative {
    
    struct File {
        std::string name;
        std::string absolutePath;
        long size;
        long lastModificationTime;
        bool isDir;
        long filesCount;
    };
    
    typedef std::vector<MediaAssetFileNative::File> fileVector_t;
    
    void getFilesList(const char *path, const char *sortType, fileVector_t *fileList);
    MediaAssetFileNative::File getFileNative(const char *path);
}

#endif /* MediaAssetFileNative_h */
