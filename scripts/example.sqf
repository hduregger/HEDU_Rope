#include "HEDU_Rope.hpp"
HEDU_ROPE_FUNCTIONS;

// Move player into helicopter as pilot

_this assignAsDriver chopper;
_this moveInDriver   chopper;

// Get helicopter position

private ["_chopperPosition"];
_chopperPosition = getPosASL chopper;

// Define Black Hawk winch position

private ["_localWinchPosition"];
_localWinchPosition = [1.45, 1.82, -0.2];

//
// We want the rope to start out as close to its real position in the world as possible
// so that it does not break or start swinging.
// Unfortunately Arma2 position functions are a bit messy so we need to trick around to
// get the correct position in ASL (sea level position).
//

private ["_worldPositionChopper", "_worldPositionWinch", "_worldPositionOffset"];

_worldPositionWinch   = chopper modelToWorld _localWinchPosition;
_worldPositionChopper = chopper modelToWorld [ 0.0, 0.0, 0.0 ];

_worldPositionOffset = [ (_worldPositionWinch select 0) - (_worldPositionChopper select 0),
                         (_worldPositionWinch select 1) - (_worldPositionChopper select 1),
                         (_worldPositionWinch select 2) - (_worldPositionChopper select 2) ];

_worldPositionWinchASL = [ (_chopperPosition select 0) + (_worldPositionOffset select 0),
                           (_chopperPosition select 1) + (_worldPositionOffset select 1),
                           (_chopperPosition select 2) + (_worldPositionOffset select 2) ];

// Create a rope with 5 nodes, starting at the helicopter's winch position and 10 meters length

_rope = [5, _worldPositionWinchASL, 10.0] call _HEDU_Rope_initialize;

private ["_nodes"];
_nodes = _rope select HEDU_ROPE_NODES_INDEX;

// Get the first node

private ["_node0"];
_node0 = _nodes select 0;

// Retrieve and attach the object associated with node0 to the helicopter at the winch location

private ["_node0Object"];
_node0Object = _node0 select HEDU_ROPE_NODE_OBJECT_INDEX;
_node0Object attachTo [chopper, _localWinchPosition];

// Tell the node to which object it was attached and at what positional offset
// so that rotation can be updated appropriately (only required for nodes attached to objects).
// NOTE: This is actually not required for the first node, but we still do it, so that you know
//       how to deal with other nodes.

_node0 set [HEDU_ROPE_NODE_ATTACHMENT_OBJECT_INDEX, chopper];
_node0 set [HEDU_ROPE_NODE_ATTACHMENT_POSITION_INDEX, _winchPosition];

// Iterate over all but the first node and set them to update.
// Remember the first node is attached to the helicopter winch position and its position will be
// update from the helicopter position.

private ["_i", "_numNodes"];
_numNodes = count _nodes;

for [{_i = 1}, {_i < _numNodes}, {_i = _i + 1}] do
{	
    private ["_node"];
    _node = _nodes select _i;
    
    _node set [HEDU_ROPE_NODE_DO_UPDATE_INDEX, true];
};

// Start simulating the rope

[_rope] spawn _HEDU_Rope_update;

// Let's add a winch for fun

private ["_winchSpeed", "_maximumRopeLength", "_minimumRopeLength"];

_winchSpeed = 2.0;
_maximumRopeLength = 80.0;
_minimumRopeLength =  0.1;

private ["_deltaTime", "_previousTime"];
_deltaTime = 1.0;
_previousTime = time;

// Hint controls

hint "You can control rope length with flaps up and down keys.";

// Let's change the stance of the person we want to 'attach' to the rope

ropeman switchMove "Datsun_Gunner02";

// Get the last node

private [ "_node4" ];
_node4 = _nodes select 4;

// Docs say while is limited in iterations, so using for here
for [{;}, {true}, {;}] do
{
   	_deltaTime = time - _previousTime;
	_previousTime = time;

    private ["_ropeLength"];
    
    _ropeLength = _rope select HEDU_ROPE_LENGTH_INDEX;

    //
    // Handle winch controls
    //
    
    if ( (inputAction "flapsUp") != 0 ) then
    {
        _ropeLength = _ropeLength - _deltaTime * _winchSpeed;
    }
    else
    {
        if ( (inputAction "flapsDown") != 0 ) then
        {
            _ropeLength = _ropeLength + _deltaTime * _winchSpeed;
        };
    };

    //
    // Limit rope length
    //
    
    if ( _ropeLength < _minimumRopeLength ) then
    {
        _ropeLength = _minimumRopeLength;
    }
    else
    {
        if ( _ropeLength > _maximumRopeLength ) then
        {
            _ropeLength = _maximumRopeLength;
        };
    };

    _rope set [HEDU_ROPE_LENGTH_INDEX, _ropeLength];
    
    // Update the position and rotation of the person 'attached' to the rope
    
    ropeman setPosASL (_node4 select HEDU_ROPE_NODE_POSITION_1_INDEX);
    ropeman setVectorUp (vectorUp (_node4 select HEDU_ROPE_NODE_OBJECT_INDEX) );

    sleep 0.001;
};