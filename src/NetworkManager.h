//
//  NetworkManager.h
//  libreTSPSWP
//
//  Created by Pierluigi Dalla Rosa on 8/13/17.
//
//

#import <Foundation/Foundation.h>
#import <PSWebSocketServer.h>
#import <OSCKit/OSCKit.h>

@interface NetworkManager : NSObject<PSWebSocketServerDelegate>

@property (nonatomic, strong) PSWebSocketServer     *server;
@property (nonatomic, strong) OSCClient *oscClient;

@property (strong,nonatomic) NSMutableArray*       __block sockets;

@property (assign) int port;

@property (assign) BOOL isOSCBroadcasting;
@property (strong,nonatomic) NSString* oscAddress;

//-(void)closeAll;
-(void)pingClients;
+(nonnull id)sharedManager;
-(void)sendMessage:(NSString*)string;
-(void)sendOSCMessage:(NSString*)string;
-(void)updateOSCAddress:(NSString*)string;
-(void)startWSServerWithPort:(int) newPort;
@end
