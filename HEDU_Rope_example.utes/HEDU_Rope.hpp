//
// Please read through this document to get an understanding of how you can use it.
//
// ! ALWAYS use the defined constants to access rope or node properties. This prevents your scripts
//   from breaking when the internal rope structure changes.
//
// ? Take a look at the example mission and example.sqf on how to setup a rope with winch and
//   an attached person.
//
// Note that the algorithm is not stable and if you move nodes too fast or let them start
// with extreme values, the rope might break beyond repair. For example you have to make sure
// the rope starts close enough to the object you want to attach it to. Also it might
// start out swinging. When testing with helicopters, I witnessed that the helicopter would
// lose altitude before the rope was instantiated and updated, there seems to be a delay after
// object instantiation in Arma2. The sudden added distance to attachment points on the helicopter
// can make the rope swing or even break. Just be aware of these thing and that you might need
// to try things (e.g. if necessary force the helicopter back to its original spot).
// You will see jerky rope movement from time to time, especially at higher speeds.
//
//
// To use the rope functions write
//
//   #include "HEDU_Rope.hpp"
//   HEDU_ROPE_FUNCTIONS;
//
// into your script.
//
// ====================================
//    TABLE OF CONTENTS
// ====================================
//
// 1. Ropes
// 2. Nodes
// 3. Things you could do
// 4. Further info
//
// ====================================
// 1. ROPES
// ====================================
//
// A rope consists of a number of nodes stored in an array and a length.
// It uses Verlet integration to compute rope node positions.
//
// rope ... [ nodes,       ... array of nodes
//            length,      ... length in meters. Array nodes will be animated and placed to create evenly spaced nodes.
//            deltaTime,   ... delta time used for the computation.
//                             CAUTION: Should NOT be changed dynamically because this usually breaks
//                                      the system. Set it to a constant value or better leave it at the default.
//            sleepTime    ... time the update function sleeps between updates to this rope.
//                             NOTE: Best leave it at the default which causes fastest updates possible.
//

// ALWAYS use these indices to access rope properties (example "_rope set [HEDU_ROPE_LENGTH_INDEX, 20.0];").

#define HEDU_ROPE_NODES_INDEX                  0
#define HEDU_ROPE_LENGTH_INDEX                 1
#define HEDU_ROPE_DELTA_TIME_INDEX             2
#define HEDU_ROPE_SLEEP_TIME_INDEX             3

// Default properties

#define HEDU_ROPE_DELTA_TIME                   0.02
#define HEDU_ROPE_SLEEP_TIME                   0.001

//
// Call initialize to create a new rope.
//
// _HEDU_Rope_initialize... takes [count, positionASL, length] as argument and creates a rope starting at positionASL with count
//                          nodes and length. The rope will start out vertically. You can change the rope length afterwards or attach nodes to objects.
//                          You can also move the nodes (set position0 and position1).
//                          If count is less than two it will be set to two automatically.
//                          If length is less than zero it will be set to zero.
//                    
//                          Things will be updated when updating starts with a call to updateRope.
//     
//                          NOTE: Here ropes with up to 5 nodes worked fine when attached to a slow moving object like a slowly moving helicopter.
//                          Using more nodes or attaching to fast moving objects can lead to visible artifacts, which look like the rope being rendered twice.
//                          I think this happens because the update script is suspended when it takes too long to update the rope and continued later but I am
//                          not sure.
//
// After tweaking node and rope values to your liking call update to spawn an update thread on the rope.
//
// _HEDU_Rope_update    ... runs in an endless loop and updates node positions
//
//                          you can still change rope length, the update will move the nodes into the new position.
//                          Note that harsh rope length changes might break the rope. My tests with simulating 
//                          a helicopter winch worked fine though.
//

#define HEDU_ROPE_FUNCTIONS \
\
private ["_HEDU_Rope_initialize", "_HEDU_Rope_update"]; \
_HEDU_Rope_initialize        = compile preprocessFile "HEDU_Rope_initialize.sqf";\
_HEDU_Rope_update            = compile preprocessFile "HEDU_Rope_update.sqf";

//
// ====================================
// 2. NODES
// ====================================
//
// Each node is an array storing the properties of the node.
// Node positions are stored as ASL (altitude sea level).
//
// Usually you can leave these entries alone.
// The doUpdate values are important when you ATTACH the node to objects (see (*) below).
//
// Sidenote: It might be more efficient to store values of the same type (e.g. velocity) in a continuous array for all nodes,
//           but benchmarking SQF seems to be impossible, so I just left it like it is.
//
//
// In the following overview [updated] indicates that the algorithm will update this value at each iteration (e.g. you can
// query isOnGround to check if a node has contact with the ground), you normally need not change these fields.
// [can be changed] indicates fields that are usually changed by you to interactively manipulate the rope look or behaviour.
//
// node ... [ object,                 ... object rendered for this node (e.g. a straight rope segment) [can be changed]
//                                        An animation is played on this object to set the length. Animation and direction
//                                        of node 0 is not updated. See animationName for more info.
//            position0,              ... position at timestep t0 (previous) [updated]
//            position1,              ... position at timestep t1 (current)  [updated]
//            velocity,               ... velocity of the node               [updated]
//            force,                  ... force on the node                  [updated]
//            distanceToPreviousNode, ... distance to node with index - 1    [updated depending on rope length] [ignored for node 0]
//            mass,                   ... mass of the node                   [can be changed] 
//            isOnGround,             ... is the node touching the ground    [updated]
//            isOnOrUnderWater,       ... is the node touching the water level or submerged [updated]
//            doUpdate,               ... see below (*)
//            attachmentPosition,     ... see below (*)
//            attachmentObject,       ... see below (*)
//            damping,                ... additional damping applied to the node [can be changed but is overridden when node touches ground/sea]
//                                        lets the the node lag behind in movement.
//            drag,                   ... drag applied to the node depending on node velocity [can be changed]
//            springFactor,           ... spring factor k applied in force computation [can be changed] [ignored for node 0]
//                                        The factor represents the spring force between the node and the previous node.
//            animationName,          ... name of the animation of the node object that should be used to update the node length. [can be changed]
//                                        the default HEDU_Rope object's animation is setup like this
//
//                                        class HEDU_Rope_Length: Translation
//                                        {
//                                            type = "translationY";
//                                            source = "user";
//                                            sourceAddress = "clamp";
//                                            selection = "HEDU_Rope_End";
//                                            axis = "HEDU_Rope_Axis";
//                                            memory = 1;
//                                            minValue = 0;
//                                            maxValue = 100;
//                                            offset0 = 0;
//                                            offset1 = 100;
//                                        };
//
//                                        note that Arma2 does not give an error when you specify a wrong animation name. Instead the
//                                        animation will just not be applied. So you should be able to set a node's animation name to ""
//                                        to disable updating the visible length of that node (the spacing is still controlled by the
//                                        distanceToPreviousNode entry). If you exchange the node object to an object created by yourself
//                                        you can of course use your own animation name that fits your object.
//            canFloat,               ... set this to true if you want the node to float. [can be changed]
//            groundOffset,           ... height offset to apply to node when touching ground.  [can be changed]
//                                        Note: The node is either over ground or over the sea, depending on what level is higher.
//            seaOffset        ]      ... height offset to apply to node when floating. Ignored when canFloat is false. [can be changed]
//                                        Note: The node is either over ground or over the sea, depending on what level is higher.
//
// The information below is important when attaching the rope to objects:
//
// (*) doUpdate ... Set this to false to indicate the node's "object" is attached to some other object. The internal node position (position0/1) is automatically
//                  updated to the attached object's position. But for correct rotational updates the "attachmentObject" and the local "attachmentPosition" in
//                  that object's model space has to be set in the node. Force and velocity are still updated but not applied in case you want to read them.
//
//                  Set this to true to let the node's "object" position be solely updated by the rope algorithm. Then "attachmentObject" and "attachmentPosition"
//                  are ignored.
//
//                  Using these values you can attach the start of the node to a helicopter winch location. You can also attach multiple nodes
//                  to an object. Note that the rope length has to be long enough to give a sensible rope representation. If the distance
//                  between two attachment positions can not be spanned with the given rope length (remember that the rope is divided into
//                  evenly spaced segments) then there will be visible gaps in the rope.
//

// ALWAYS use these indices to access node properties (example "_velocity = _node select HEDU_ROPE_NODE_VELOCITY_INDEX;").

#define HEDU_ROPE_NODE_OBJECT_INDEX                 0
#define HEDU_ROPE_NODE_POSITION_0_INDEX             1
#define HEDU_ROPE_NODE_POSITION_1_INDEX             2
#define HEDU_ROPE_NODE_VELOCITY_INDEX               3
#define HEDU_ROPE_NODE_FORCE_INDEX                  4
#define HEDU_ROPE_NODE_DISTANCE_TO_PREVIOUS_INDEX   5
#define HEDU_ROPE_NODE_MASS_INDEX                   6
#define HEDU_ROPE_NODE_IS_ON_GROUND_INDEX           7
#define HEDU_ROPE_NODE_IS_ON_OR_UNDER_WATER_INDEX   8
#define HEDU_ROPE_NODE_DO_UPDATE_INDEX              9
#define HEDU_ROPE_NODE_ATTACHMENT_POSITION_INDEX   10
#define HEDU_ROPE_NODE_ATTACHMENT_OBJECT_INDEX     11
#define HEDU_ROPE_NODE_DAMPING_INDEX               12
#define HEDU_ROPE_NODE_DRAG_INDEX                  13
#define HEDU_ROPE_NODE_SPRING_FACTOR_INDEX         14
#define HEDU_ROPE_NODE_ANIMATION_NAME_INDEX        15
#define HEDU_ROPE_NODE_CAN_FLOAT_INDEX             16
#define HEDU_ROPE_NODE_GROUND_OFFSET_INDEX         17
#define HEDU_ROPE_NODE_SEA_OFFSET_INDEX            18

// Overriding properties

#define HEDU_ROPE_NODE_TERRAIN_DAMPING             0.1
#define HEDU_ROPE_NODE_SEA_DAMPING                 0.1

// Default properties

#define HEDU_ROPE_NODE_MASS                         5.0
#define HEDU_ROPE_NODE_DRAG                        0.05
#define HEDU_ROPE_NODE_SPRING_FACTOR             200.0
#define HEDU_ROPE_NODE_ANIMATION_NAME              "HEDU_Rope_Length"

//
// ====================================
// 3. THINGS YOU COULD DO
// ====================================
//
// - Attach two or more nodes of the rope to an object
// - Read out the force on a node and apply it to another object
// - Check if a node touches water and attach a nearby swimmer to it
// - Release a person attached to a node if the node touches ground
// - 'Attach' objects to nodes by querying the node position1 and updating object positions from that, this usually works
//   better than using attachTo to attach object to nodes.
// - 'Attach' a standing person to the last node if the person can grab the rope when the node's speed is below some threshold
// - Change the damping value on the second node of a rope attached to a helicopter to simulate the operator holding the rope
// - Change the mass and drag value of the last node after you attached a load to that node
// - ...
//
// ====================================
// 4. FURTHER INFO
// ====================================
//
// If you are further interested in verlet integration and how the update algorithm works, it's based on info at
//
// http://en.wikipedia.org/wiki/Verlet_integration
// http://www.fisica.uniud.it/~ercolessi/md/md/node21.html
// http://www.ch.embnet.org/MD_tutorial/pages/MD.Part1.html#Velocity%20Verlet
// http://xbeams.chem.yale.edu/~batista/vaa/node60.html
// http://www2.ph.ed.ac.uk/~graeme/compmeth/verlet.html
//
