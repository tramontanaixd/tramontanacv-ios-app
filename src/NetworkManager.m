//
//  NetworkManager.m
//  libreTSPSWP
//
//  Created by Pierluigi Dalla Rosa on 8/13/17.
//
//

#import "NetworkManager.h"

#define DEFAULT_WS_PORT     9088
#define DEFAULT_OSC_PORT    9090
#define RAND_FROM_TO(min, max) (min + arc4random_uniform(max - min + 1))

@implementation NetworkManager


+ (id)sharedManager {
    static NetworkManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    _server = [PSWebSocketServer serverWithHost:nil port:DEFAULT_WS_PORT];
    _server.delegate = self;
    [_server start];
    
    
    _sockets =[[NSMutableArray alloc]init];
    // [self pingClients];
    _isOSCBroadcasting = NO;
    
    
    return self;
}

-(void)startWSServerWithPort:(int) newPort
{
    
    _server = [PSWebSocketServer serverWithHost:nil port:newPort];
    _server.delegate = self;
    [_server start];
    _sockets =[[NSMutableArray alloc]init];
}

#pragma mark - PSWebSocketServerDelegate
-(void)sendMessage:(NSString*)string{
    for (PSWebSocket* wsTmp in _sockets) {
        
        [wsTmp send:string];
    }
}
-(void)sendOSCMessage:(NSString*)string{
    //[_oscClient sendMessage:string to:oscAddress];
}
-(void)updateOSCAddress:(NSString*)string{
    
}
-(void)pingClients{
    //NSLog(@"ping");
    for (PSWebSocket* wsTmp in _sockets) {
        
        [wsTmp send:@"{\"m\":\"test1\"}"];
    }
    [self performSelector:@selector(pingClients) withObject:nil afterDelay:5.0];
}
- (void)serverDidStart:(PSWebSocketServer *)server {
    NSLog(@"Server did start…");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"wsServerUpdate" object:nil userInfo:@{@"m":@"Server did start…"}];
    });
    
}
- (void)serverDidStop:(PSWebSocketServer *)server {
    NSLog(@"Server did stop…");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"wsServerUpdate" object:nil userInfo:@{@"m":@"Server did stop…"}];
}
- (void)server:(PSWebSocketServer *)server didFailWithError:(NSError *)error {
    NSLog(@"Server Failed");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"wsServerUpdate" object:nil userInfo:@{@"m":@"Server did fail…"}];
    
}
- (BOOL)server:(PSWebSocketServer *)server acceptWebSocketWithRequest:(NSURLRequest *)request {
    NSLog(@"Server should accept request: %@", request);
    
    return YES;
}
- (void)server:(PSWebSocketServer *)server webSocket:(PSWebSocket *)webSocket didReceiveMessage:(id)message {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"wsServerUpdate" object:nil userInfo:@{@"m":@"Server received message…"}];
    // [[NSNotificationCenter defaultCenter] postNotificationName:@"wsServerUpdate" object:@{@"m":@"Server did start…"}];
#if true
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(RAND_FROM_TO(1.0,2.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSTimeInterval timeInMiliseconds = [[NSDate date] timeIntervalSince1970];
        printf("%f", timeInMiliseconds);
        [webSocket send:@"{\"m\":\"test\"}"];
        
        
    });
#endif
    
    NSError *error = nil;
    NSData* data = [message dataUsingEncoding:NSUTF8StringEncoding];
    id object = [NSJSONSerialization
                 JSONObjectWithData:data
                 options:0
                 error:&error];
    
    if(error) {
        /* JSON was malformed*/
        [webSocket send:@"{\"error\":\"BAD JSON\"}"];
    }
    
    // the originating poster wants to deal with dictionaries;
    // assuming you do too then something like this is the first
    // validation step:
    if([object isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *results = object;
        
        if([[results allKeys] containsObject:@"m"])
        {
            NSString* keyDirective      = [results valueForKey:@"m"];
            
            NSLog(@"received %@",keyDirective);
            
            //**** ACTUATE ****//
            NSDictionary *dictTmp;
            if([keyDirective isEqualToString:@"lockAE"])
            {
                dictTmp = @{@"m":keyDirective};
                
            }else if([keyDirective isEqualToString:@"unlockAE"])
            {
                dictTmp = @{@"m":keyDirective};
            }
            else if([keyDirective isEqualToString:@"save"])
            {
                dictTmp = @{@"m":keyDirective};
            }
            else if([keyDirective isEqualToString:@"captureBg"])
            {
                dictTmp = @{@"m":keyDirective};
            }
            else if([keyDirective isEqualToString:@"blur"] && [[results allKeys] containsObject:@"val"])
            {
                dictTmp = @{@"m":keyDirective,@"v":[results objectForKey:@"val"]};
            }
            else if([keyDirective isEqualToString:@"threshold"]  && [[results allKeys] containsObject:@"val"])
            {
                dictTmp = @{@"m":keyDirective,@"v":[results objectForKey:@"val"]};
            }
            else if([keyDirective isEqualToString:@"blobs"]  && [[results allKeys] containsObject:@"max"]  && [[results allKeys] containsObject:@"min"]  && [[results allKeys] containsObject:@"num"])
            {
                dictTmp = @{@"m":keyDirective,@"max":[results objectForKey:@"max"],@"min":[results objectForKey:@"min"],@"num":[results objectForKey:@"num"]};
            }
            if (dictTmp !=NULL) {
                 [[NSNotificationCenter defaultCenter] postNotificationName:@"controlMsgReceived" object: self userInfo:dictTmp];
            }
        }
        
        else{
            
            [webSocket send:@"{\"m\":\"error\",\"type\":\"missing Directive\"}"];
            return;
        }
        /* proceed with results as you like; the assignment to
         an explicit NSDictionary * is artificial step to get
         compile-time checking from here on down (and better autocompletion
         when editing). You could have just made object an NSDictionary *
         in the first place but stylistically you might prefer to keep
         the question of type open until it's confirmed */
    }
    else
    {
        /* there's no guarantee that the outermost object in a JSON
         packet will be a dictionary; if we get here then it wasn't,
         so 'object' shouldn't be treated as an NSDictionary; probably
         you need to report a suitable error condition */
    }
    
}
- (void)server:(PSWebSocketServer *)server webSocketDidOpen:(PSWebSocket *)webSocket {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"wsServerUpdate" object:nil userInfo:@{@"m":@"Server did open…"}];
    if(![_sockets containsObject:webSocket])
    {
        [_sockets addObject:webSocket];
    }
    
}
- (void)server:(PSWebSocketServer *)server webSocket:(PSWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"Server websocket did close with code: %@, reason: %@, wasClean: %@", @(code), reason, @(wasClean));
    [[NSNotificationCenter defaultCenter] postNotificationName:@"wsServerUpdate" object:nil userInfo:@{@"m":@"Server did close…"}];
    if([_sockets containsObject:webSocket])
    {
        [_sockets removeObject:webSocket];
        
    }
    
}
- (void)server:(PSWebSocketServer *)server webSocket:(PSWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"Server websocket did fail with error: %@", error);
    if([_sockets containsObject:webSocket])
    {
        [_sockets removeObject:webSocket];
        
    }
    
    
}


@end
