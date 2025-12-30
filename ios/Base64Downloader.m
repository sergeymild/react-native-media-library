//
//  Base64Downloader.m
//  MediaLibrary
//

#import "Base64Downloader.h"

@implementation Base64Downloader

+ (void)downloadWithUrl:(NSString *)urlString
             completion:(void (^)(NSString * _Nullable result))completion {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        completion(nil);
        return;
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!data || error) {
            completion(nil);
            return;
        }

        NSString *base64String = [data base64EncodedStringWithOptions:0];
        NSString *result = [NSString stringWithFormat:@"{\"base64\": \"%@\"}", base64String];
        completion(result);
    }];
    [task resume];
}

@end
