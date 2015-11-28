//
//  GameScene.m
//  ISSM
//
//  Created by Alec Kriebel on 11/29/14.
//  Copyright (c) 2014 AlecKriebel. All rights reserved.
//

#import "GameScene.h"

@interface GameScene () <SKPhysicsContactDelegate> {
    
    SKSpriteNode *selectedNode;
    
    SKLabelNode *pausedLabel;
    SKLabelNode *gameOverLabel;
    
    SKAction *glacierCompoundSound;
    SKAction *snowflakeSpawnSound;
    
    int bin1;
    int bin2;
    int bin3;
    int bin4;
    int bin5;
    
    bool gameIsRunning;
    
    float gravity;
}

@end

@implementation GameScene

#define kBin 5
#define kSnowflakeLimit 10

/*
 
 --------------------------------------Game State Functions--------------------------------------
 
 */

//Function that shows the menu when the game opens or the user restarts
-(void)showMenu {

    //Adds the buttons: play, research, and sound buttons
    [self addChild:[self playButtonNode]];
    [self addChild:[self researchButtonNode]];
    [self addChild:[self soundButtonNode]];

}

-(void)startGame {
    
    SKNode *node;
    
    //Removes all the buttons from the scene
    for (node in self.children) {
        if ([[node name] isEqualToString:@"playButtonNode"] || [[node name] isEqualToString:@"researchButtonNode"] || [[node name] isEqualToString:@"soundButtonNode"]) {
            
            [node removeFromParent];
            
        }
    }
    
    [gameOverLabel setHidden:YES];
    
    //Game is now running
    gameIsRunning = YES;
    
    //Adds the pause button
    [self addChild: [self pauseButtonNode]];
    
    //Adds the "Pause" text shown when the game is paused
    pausedLabel = [[SKLabelNode alloc] initWithFontNamed:@"Futura"];
    pausedLabel.position = CGPointMake(self.size.width/2, self.size.height/2);
    pausedLabel.fontColor = [SKColor blackColor];
    pausedLabel.fontSize = 64;
    pausedLabel.zPosition = 3;
    pausedLabel.text = @"Paused";
    pausedLabel.hidden = YES;
    [self addChild:pausedLabel];
    
    //Creates the snowflake spawning and speeding up loop
    id wait = [SKAction waitForDuration:1.5];
    id run = [SKAction runBlock:^{
        [self createSnowflake];
        [self updateSpeed];
    }];
    
    //Add the bin counters to the scene
    [self addCounters];
    
    //Starts the snowflake spawn and update speed function
    [self runAction:[SKAction repeatActionForever:[SKAction sequence:@[wait, run]]] withKey:@"CreateSnowflakes"];
    
}

//Resets the game state to prepare for next game, also tells the player they have lost
-(void)loseGame {
    
    [self removeSnowflakes];
    
    gameIsRunning = NO;
    
    [self resetGameData];
    [self removeCounters];
    
    for (SKNode *node in self.children) {
        if ([[node name] isEqualToString:@"pauseButtonNode"]) {
            
            [node removeFromParent];
        }
    }
    
    [pausedLabel removeFromParent];
    
    [self removeActionForKey:@"CreateSnowflakes"];
    
    [gameOverLabel setHidden:NO];
    
    [self showMenu];
}

/*
 
 --------------------------------------Node Creation Functions--------------------------------------
 
 */

//Function that specifies and creates the play button
- (SKLabelNode *)playButtonNode
{
    SKLabelNode *playNode = [[SKLabelNode alloc] initWithFontNamed:@"Futura"];
    playNode.position = CGPointMake(self.size.width/2, self.size.height/2+25);
    playNode.fontColor = [SKColor blackColor];
    playNode.fontSize = 76;
    playNode.text = @"Play";
    playNode.name = @"playButtonNode";
    playNode.zPosition = 2.0;
    return playNode;
}

//Function that specifies and creates the research button
- (SKLabelNode *)researchButtonNode
{
    SKLabelNode *reNode = [[SKLabelNode alloc] initWithFontNamed:@"Futura"];
    reNode.position = CGPointMake(self.size.width/2, self.size.height/2-75);
    reNode.fontColor = [SKColor blackColor];
    reNode.fontSize = 76;
    reNode.text = @"See Research";
    reNode.name = @"researchButtonNode";
    reNode.zPosition = 2.0;
    return reNode;
}

//Function that specifies and creates the sound button
- (SKLabelNode *)soundButtonNode
{
    SKLabelNode *soundNode = [[SKLabelNode alloc] initWithFontNamed:@"Futura"];
    soundNode.position = CGPointMake(self.size.width/2, self.size.height/2-175);
    soundNode.fontColor = [SKColor blackColor];
    soundNode.fontSize = 76;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"sound"]) {
        soundNode.text = @"Sound: On";
    } else {
        soundNode.text = @"Sound: Off";
    }
    
    soundNode.name = @"soundButtonNode";
    soundNode.zPosition = 2.0;
    return soundNode;
}

//Function that specifies and creates the pause button
- (SKSpriteNode *)pauseButtonNode
{
    SKSpriteNode *pauseNode = [SKSpriteNode spriteNodeWithImageNamed:@"pause"];
    pauseNode.position = CGPointMake(self.size.width-50, self.size.height-140);
    pauseNode.name = @"pauseButtonNode";
    pauseNode.scale = .4;
    pauseNode.zPosition = 2.0;
    return pauseNode;
}

//Function that specifies and creates the cloud
- (SKSpriteNode *)cloudNode {
    
    SKSpriteNode *cloud = [SKSpriteNode spriteNodeWithImageNamed:@"cloud"];
    cloud.position = CGPointMake(self.size.width/2-70, self.size.height/1.19);
    cloud.xScale = 3;
    cloud.yScale = 1;
    cloud.zPosition = 1;
    return cloud;
}

//Function that specifies and create the background image
- (SKSpriteNode *)bgNode {
    
    SKSpriteNode *bgImage = [SKSpriteNode spriteNodeWithImageNamed:@"bg"];
    bgImage.position = CGPointMake(self.size.width/2, self.size.height/2);
    bgImage.xScale = 1.5;
    bgImage.yScale = 1.5;
    bgImage.zPosition = -1;
    return bgImage;
    
}

-(void)addCounters {
    
    SKLabelNode *bin1Node = [[SKLabelNode alloc] initWithFontNamed:@"Futura"];
    bin1Node.position = CGPointMake(self.size.width/5 - 95, self.size.height/5);
    bin1Node.fontColor = [SKColor blackColor];
    bin1Node.fontSize = 76;
    bin1Node.text = @"0";
    bin1Node.name = @"bin1Label";
    bin1Node.zPosition = 2.0;
    [self addChild:bin1Node];
    
    SKLabelNode *bin2Node = [[SKLabelNode alloc] initWithFontNamed:@"Futura"];
    bin2Node.position = CGPointMake(self.size.width/5*2 - 95, self.size.height/5);
    bin2Node.fontColor = [SKColor blackColor];
    bin2Node.fontSize = 76;
    bin2Node.text = @"0";
    bin2Node.name = @"bin2Label";
    bin2Node.zPosition = 2.0;
    [self addChild:bin2Node];
    
    SKLabelNode *bin3Node = [[SKLabelNode alloc] initWithFontNamed:@"Futura"];
    bin3Node.position = CGPointMake(self.size.width/5*3 - 95, self.size.height/5);
    bin3Node.fontColor = [SKColor blackColor];
    bin3Node.fontSize = 76;
    bin3Node.text = @"0";
    bin3Node.name = @"bin3Label";
    bin3Node.zPosition = 2.0;
    [self addChild:bin3Node];
    
    SKLabelNode *bin4Node = [[SKLabelNode alloc] initWithFontNamed:@"Futura"];
    bin4Node.position = CGPointMake(self.size.width/5*4 - 95, self.size.height/5);
    bin4Node.fontColor = [SKColor blackColor];
    bin4Node.fontSize = 76;
    bin4Node.text = @"0";
    bin4Node.name = @"bin4Label";
    bin4Node.zPosition = 2.0;
    [self addChild:bin4Node];
    
    SKLabelNode *bin5Node = [[SKLabelNode alloc] initWithFontNamed:@"Futura"];
    bin5Node.position = CGPointMake(self.size.width - 95, self.size.height/5);
    bin5Node.fontColor = [SKColor blackColor];
    bin5Node.fontSize = 76;
    bin5Node.text = @"0";
    bin5Node.name = @"bin5Label";
    bin5Node.zPosition = 2.0;
    [self addChild:bin5Node];
    
}

//Function that creates a snowflake
-(void)createSnowflake {
    
    //Sets a random location on the x axis, and constant y axis to be created at
    CGPoint location = CGPointMake([self randomNumberInRange:84 range2:self.size.width-84], self.size.height-100);
    
    //Creates the sprite
    SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:@"snowflake"];
    
    //Sets a random scale for each snowflake between 40% and 50% of the original image size
    float scaleNumber  = [self randomNumberInRange:40 range2:50]/100;
    
    //Sets the scale, x and y are the same. Image is a square
    sprite.xScale = scaleNumber;
    sprite.yScale = scaleNumber;
    //Sets where the layer is
    sprite.zPosition = 0;
    //Sets the location
    sprite.position = location;
    
    //Sets where the physics should react to
    sprite.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:sprite.size.height / 2];
    //Specifies that the sprite can change with respect to physics
    sprite.physicsBody.dynamic = YES;
    sprite.physicsBody.allowsRotation = YES;
    
    //Name the sprite snowflake to further reference
    [sprite setName:@"snowflake"];
    
    [self addChild:sprite];
    
    //If sound is on, play the spawn sound
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"sound"])
        [sprite runAction:snowflakeSpawnSound];
}

-(void)removeCounters {
    
    for (SKLabelNode *node in self.children) {
        if (([[node name] isEqualToString:@"bin1Label"]) || ([[node name] isEqualToString:@"bin2Label"]) || ([[node name] isEqualToString:@"bin3Label"]) || ([[node name] isEqualToString:@"bin4Label"]) || ([[node name] isEqualToString:@"bin5Label"])) {
            
            [node removeFromParent];
        }
    }
}

-(void)removeSnowflakes {
    for (SKLabelNode *node in self.children) {
        if ([[node name] isEqualToString:@"snowflake"]) {
            [node removeFromParent];
        }
    }
}

/*
 
 --------------------------------------Game Checking/Updating Functions--------------------------------------
 
 */

//Function that returns random number in range
-(float)randomNumberInRange:(NSUInteger)f1 range2:(NSUInteger)f2 {
    
    return ((arc4random()%(f2-f1)) + (f1));
    
}

//Function that updates the speed, called when a snowflake us spawned every 1.5s
-(void)updateSpeed {
    
    //Subtracts -.075 from the global variable "gravity"
    gravity -= .075;
    //Sets the world's gravity
    self.physicsWorld.gravity = CGVectorMake(0.0, gravity);
    
}

//Function that checks if the snowflakes should be compounded
-(void)checkSnowflakes {
    
    SKSpriteNode *node;

    //Goes through each node, checks if it is a snowflake, checks if it is in the correct height,
    for (node in self.children) {
        if ([[node name] isEqualToString:@"snowflake"]) {
            if (node.position.y < self.size.height/5) {
                //If sound is on, play the compound sound
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"sound"])
                    [self.scene runAction: glacierCompoundSound];
                
                //Partitions the screens for 5 bins, adds snowflakes if they are in width range
                if (node.position.x <= self.size.width/5) {
                    bin1 += 1;
                    NSLog(@"Bin1 = %d", bin1);
                } else if ((node.position.x > self.size.width/5) && (node.position.x <= self.size.width/5*2)) {
                    bin2 += 1;
                    NSLog(@"Bin2 = %d", bin2);
                } else if ((node.position.x > self.size.width/5*2) && (node.position.x <= self.size.width/5*3)) {
                    bin3 += 1;
                    NSLog(@"Bin3 = %d", bin3);
                } else if ((node.position.x > self.size.width/5*3) && (node.position.x <= self.size.width/5*4)) {
                    bin4 += 1;
                    NSLog(@"Bin4 = %d", bin4);
                } else if (node.position.x > self.size.width/5*4) {
                    bin5 += 1;
                    NSLog(@"Bin5 = %d", bin5);
                }
                
                //Updates text on labels
                [self updateLabels];
                
                //Check to see if any bin is over the limit
                [self checkIfLost];
                
                //Remove the snowflake; free up memory
                [node removeFromParent];
                
                }
            }
        }
}

-(void)updateLabels {
    
    for (SKLabelNode *node in self.children) {
        if ([[node name] isEqualToString:@"bin1Label"]) {
            
            node.text = [NSString stringWithFormat:@"%d", bin1];
            
        } else if ([[node name] isEqualToString:@"bin2Label"]) {
            
            node.text = [NSString stringWithFormat:@"%d", bin2];
            
        } else if ([[node name] isEqualToString:@"bin3Label"]) {
            
            node.text = [NSString stringWithFormat:@"%d", bin3];
            
        } else if ([[node name] isEqualToString:@"bin4Label"]) {
            
            node.text = [NSString stringWithFormat:@"%d", bin4];
            
        } else if ([[node name] isEqualToString:@"bin5Label"]) {
            
            node.text = [NSString stringWithFormat:@"%d", bin5];
        }
    }
}

//Resets the numbers and data used during gameplay
-(void)resetGameData {
    
    bin1 = 0;
    bin2 = 0;
    bin3 = 0;
    bin4 = 0;
    bin5 = 0;
    
    gravity = -.5;
    self.physicsWorld.gravity = CGVectorMake(0.0, gravity);
    
}

/*
 
 --------------------------------------Premade Game State Functions--------------------------------------
 
 */

//Called as soon the the scene is loaded
-(void)didMoveToView:(SKView *)view {
    /* Setup your scene here */
    
    //App loads with the game no running, menu si open
    gameIsRunning = NO;
    
    //Gravity starts at -.5 to simulate snowflake drift
    gravity = -.5;
    
    //Create dict for each bun
    

    self.physicsWorld.gravity = CGVectorMake(0.0, gravity);
    self.physicsWorld.contactDelegate = self;
    
    //Create the background
    [self addChild: [self bgNode]];
    [self addChild: [self cloudNode]];
    
    //Create and queue sounds to play
    glacierCompoundSound = [SKAction playSoundFileNamed:@"glacier.mp3" waitForCompletion:NO];
    snowflakeSpawnSound = [SKAction playSoundFileNamed:@"spawn.mp3" waitForCompletion:NO];
    
    //Start by showing the menu
    [self showMenu];
    
    //Add the gameover label to hidden/unhidden later
    gameOverLabel = [[SKLabelNode alloc] initWithFontNamed:@"Futura"];
    gameOverLabel.position = CGPointMake(self.size.width/2, self.size.height/2 + 150);
    gameOverLabel.fontColor = [SKColor blackColor];
    gameOverLabel.fontSize = 88;
    gameOverLabel.zPosition = 3;
    gameOverLabel.text = @"Game Over!";
    gameOverLabel.hidden = YES;
    [self addChild:gameOverLabel];
    
}

//Called before a new frame is rendered
-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    
    //If the game is running (not a menu)
    if (gameIsRunning) {
        
        //check for where the snowflakes are
        [self checkSnowflakes];
        
    }
}

-(void)checkIfLost {
    
    if ((bin1 >= kSnowflakeLimit) || (bin2 >= kSnowflakeLimit) || (bin3 >= kSnowflakeLimit) || (bin4 >= kSnowflakeLimit) || (bin5 >= kSnowflakeLimit)) {
        
        [self loseGame];
    }
}

/*
 
 --------------------------------------TOUCH FUNCTIONS--------------------------------------
 
*/

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    UITouch *touch = [touches anyObject];
    CGPoint positionInScene = [touch locationInNode:self];
    //Send the touches to this function
    [self selectNodeForTouch:positionInScene];

}

- (void)selectNodeForTouch:(CGPoint)touchLocation {
    
    //Create nodes to reference
    SKSpriteNode *touchedNode = (SKSpriteNode *)[self nodeAtPoint:touchLocation];
    SKLabelNode *touchedLabel = (SKLabelNode *)[self nodeAtPoint:touchLocation];
    
    //What to do when the pause button is tapped
    if ([touchedNode.name isEqualToString:@"pauseButtonNode"]) {
        //What to do if paused
        if (self.scene.paused == YES) {
            //Unpause and hide the pause label
            [self.scene.view setPaused:NO];
            [pausedLabel setHidden:YES];
        
        //What to do if not paused
        } else {
            
            //Pause the game and show "Pause"
            SKAction *showPause = [SKAction runBlock:^{
                [pausedLabel setHidden:NO];
            }];
            
            [pausedLabel runAction:showPause completion:^{
                [self.scene.view setPaused:YES];
            }];
        }
    }
    
    //What to do if play is tapped
    if ([touchedNode.name isEqualToString:@"playButtonNode"])
        [self startGame]; //Start the game
    
    //What to do if sound is tapped
    if ([touchedLabel.name isEqualToString:@"soundButtonNode"]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"sound"]) { //If sound is on
            
            //Turn sound off
            [touchedLabel setText:@"Sound: Off"];
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"sound"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            NSLog(@"Sound: %d", [[NSUserDefaults standardUserDefaults] boolForKey:@"sound"]);
            
        } else { //If sound is off
            
            //Turn sound on
            [touchedLabel setText:@"Sound: On"];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"sound"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            NSLog(@"Sound: %d", [[NSUserDefaults standardUserDefaults] boolForKey:@"sound"]);
            
        }
    }
    
    //If research button is tapped
    if ([touchedNode.name isEqualToString:@"researchButtonNode"])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"https://issm.jpl.nasa.gov/about/"]]; //Go to the JPL link
    
    if(![selectedNode isEqual:touchedNode]) {
        [selectedNode removeAllActions];
        
        selectedNode = touchedNode;
        
        //If the touched node is snowflake
        if([[touchedNode name] isEqualToString:@"snowflake"]) {
            
            //Change the texture and make it so it no longer falls
            [selectedNode setTexture:[SKTexture textureWithImageNamed:@"selectedsnowflake"]];
            selectedNode.physicsBody.dynamic = NO;
            
        }
    }
}

//Trigger when a touch is moved
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint positionInScene = [touch locationInNode:self];
    CGPoint previousPosition = [touch previousLocationInNode:self];
    
    CGPoint translation = CGPointMake(positionInScene.x - previousPosition.x, positionInScene.y - previousPosition.y);
    
    //Trigger the function panForTranslation
    [self panForTranslation:translation];
}

//Change the location based on where the finger is dragged
- (void)panForTranslation:(CGPoint)translation {
    CGPoint position = [selectedNode position];
    if([[selectedNode name] isEqualToString:@"snowflake"]) {
        [selectedNode setPosition:CGPointMake(position.x + translation.x, position.y + translation.y)];
    }
}

//Triggered when finger is removed from screen
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

    //If the node is a snowflake, set is back to normal after being dragged
    if ([[selectedNode name] isEqualToString:@"snowflake"]) {
        
        selectedNode.physicsBody.dynamic = YES;
        
        [selectedNode setTexture:[SKTexture textureWithImageNamed:@"snowflake"]];
    }
}

@end