#import "BUGPivotalTrackerInterface.h"
#import "zlib.h"

typedef void (^SessionCompletionHandler)(NSData *data, NSURLResponse *response, NSError *error);
typedef void (^RequestSetupBlock)(NSMutableURLRequest *);

@interface BUGPivotalTrackerInterface ()
@property (strong, nonatomic, readwrite) NSString *apiToken, *projectID;

@property (assign, nonatomic, readwrite) NSInteger pendingUploads;
@property (strong, nonatomic, readwrite) NSString *storyID;
@property (strong, nonatomic, readwrite) NSMutableArray *attachemnts;
@property (strong, nonatomic, readwrite) CompletionBlock createStoryCompletion;
@end

static NSString const *basePath = @"https://www.pivotaltracker.com/services/v5/projects/";

@implementation BUGPivotalTrackerInterface

- (instancetype)initWithAPIToken:(NSString *)token trackerProjectID:(NSString *)projectID {
    if (self = [super init]) {
        self.apiToken = token;
        self.projectID = projectID;
    }
    return self;
}

- (void)createStoryWithStoryTitle:(NSString *)title storyDescription:(NSString *)description image:(NSData *)jpegImageData text:(NSData *)textData completion:(CompletionBlock)completion {
    [self prepareForNewStory];
    
    self.createStoryCompletion = completion;
    __weak __typeof(self)weakSelf = self;
    [self createStoryWithStoryTitle:title storyDescription:description completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if ([(NSHTTPURLResponse *)response statusCode] / 100 != 2) {
            [weakSelf completeWithSuccess:NO error:error];
            return;
        }
        
        NSError *jsonError;
        NSDictionary *storyDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        if (!jsonError) {
            self.storyID = storyDictionary[@"id"];
            [weakSelf uploadJPEGImageData:jpegImageData];
            [weakSelf uploadTextData:textData];
        }
    }];
}

- (void)cancel {
    [[NSURLSession sharedSession] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        NSMutableArray *allTasks = [NSMutableArray arrayWithArray:dataTasks];
        [allTasks addObjectsFromArray:uploadTasks];
        for (NSURLSessionTask *task in allTasks) {
            [task cancel];
        }
    }];
}

#pragma mark - Private

- (void)prepareForNewStory {
    self.pendingUploads = 0;
    self.storyID = nil;
    self.attachemnts = [[NSMutableArray alloc] initWithCapacity:2];
    self.createStoryCompletion = nil;
}

- (void)createStoryWithStoryTitle:(NSString *)title storyDescription:(NSString *)description completionHandler:(SessionCompletionHandler)completion {
    NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"bug", @"story_type",
                                    title, @"name",
                                    description, @"description",
                                    nil];
    
    NSURLSessionTask *task = [self dataTaskForPath:@"stories" withRequestSetup:^(NSMutableURLRequest *request) {
        NSString *body = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:nil] encoding:NSUTF8StringEncoding];
        [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    } completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (completion) { completion(data, response, error); }
    }];
    
    [task resume];
}
         
- (void)uploadJPEGImageData:(NSData *)imageData {
    if (!imageData) {
        [self dataUploadDidComplete];
        return;
    }
    
    self.pendingUploads ++;
    
    NSURLSessionTask *uploadTask = [self dataTaskForPath:@"uploads" withRequestSetup:^(NSMutableURLRequest *request) {
        NSString *boundary = @"ThisIsTheBoundary";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        
        NSMutableData *body = [NSMutableData data];
        NSString *fileName = @"screenshot.png";
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding: NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n",fileName] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Type: image/jpeg\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:imageData];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [request setHTTPBody:body];
    } completionHandler:[self uploadCompletionHandler]];
    
    [uploadTask resume];
}

- (void)uploadTextData:(NSData *)textData {
    if (!textData) {
        [self dataUploadDidComplete];
        return;
    }
    
    self.pendingUploads ++;
    textData = [self gzipDeflate:textData];
    
    NSURLSessionTask *uploadTask = [self dataTaskForPath:@"uploads" withRequestSetup:^(NSMutableURLRequest *request) {
        NSString *boundary = @"ThisIsTheBoundary";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
        NSMutableData *body = [NSMutableData data];
        NSString *dateString = [[NSDate date] description];
        dateString = [dateString substringToIndex:dateString.length - 6];
        NSString *fileName = [NSString stringWithFormat:@"log - %@.txt", dateString];
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding: NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n",fileName] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Type: text/plain\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:textData];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [request setHTTPBody:body];
    } completionHandler:[self uploadCompletionHandler]];
    
    [uploadTask resume];
}

- (SessionCompletionHandler)uploadCompletionHandler {
    return [^(NSData *data, NSURLResponse *response, NSError *error) {
        if ([(NSHTTPURLResponse *)response statusCode] / 100 == 2 && data) {
            NSError *error;
            NSDictionary *logDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            if (!error) {
                [self.attachemnts addObject:logDictionary];
            }
            self.pendingUploads --;
            [self dataUploadDidComplete];
        }
    } copy];
}

- (void)dataUploadDidComplete {
    if (self.pendingUploads) {
        return;
    }
    
    if (self.attachemnts.count) {
        [self attachUploadsToStory];
    } else if (self.createStoryCompletion) {
        [self completeWithSuccess:YES error:nil];
    }
}

- (void)attachUploadsToStory {
    __weak __typeof(self)weakSelf = self;
    NSURLSessionTask *dataTask = [self dataTaskForPath:[NSString stringWithFormat:@"stories/%@/comments", self.storyID] withRequestSetup:^(NSMutableURLRequest *request) {
        NSString *body = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:@{@"file_attachments": self.attachemnts} options:0 error:nil] encoding:NSUTF8StringEncoding];
        [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:weakSelf.apiToken forHTTPHeaderField:@"X-TrackerToken"];
        [request setHTTPMethod:@"POST"];
    } completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [weakSelf completeWithSuccess:YES error:nil];
    }];
    [dataTask resume];
}

- (void)completeWithSuccess:(BOOL)success error:(NSError *)error {
    if (self.createStoryCompletion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.createStoryCompletion(success, error);
        });
    }
}

- (NSURLSessionTask *)dataTaskForPath:(NSString *)path withRequestSetup:(RequestSetupBlock)requestSetup completionHandler:(SessionCompletionHandler)completionHandler {
    NSMutableURLRequest *request = [self requestForPath:path];
    
    [request setValue:self.apiToken forHTTPHeaderField:@"X-TrackerToken"];
    [request setHTTPMethod:@"POST"];
    
    if (requestSetup) {
        requestSetup(request);
    }
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:completionHandler];
    return task;
}

- (NSMutableURLRequest *)requestForPath:(NSString *)path {
    return [[NSMutableURLRequest alloc] initWithURL:[self urlForPath:path]];
}

- (NSURL *)urlForPath:(NSString *)path {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%@/", basePath, self.projectID, path]];
}

#pragma mark - Log File Compression

- (NSData *)gzipDeflate:(NSData*)data {
    if ([data length] == 0) return data;
    
    z_stream strm;
    
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.next_in=(Bytef *)[data bytes];
    strm.avail_in = [data length];
    
    // Compresssion Levels:
    //   Z_NO_COMPRESSION
    //   Z_BEST_SPEED
    //   Z_BEST_COMPRESSION
    //   Z_DEFAULT_COMPRESSION
    
    if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
    
    NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
    
    do {
        
        if (strm.total_out >= [compressed length])
            [compressed increaseLengthBy: 16384];
        
        strm.next_out = [compressed mutableBytes] + strm.total_out;
        strm.avail_out = [compressed length] - strm.total_out;
        
        deflate(&strm, Z_FINISH);
        
    } while (strm.avail_out == 0);
    
    deflateEnd(&strm);
    
    [compressed setLength: strm.total_out];
    return [NSData dataWithData:compressed];
}

@end
