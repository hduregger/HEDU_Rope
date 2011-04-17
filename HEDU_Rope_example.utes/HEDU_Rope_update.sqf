#include "HEDU_Rope.hpp"

private [ "_rope", "_nodes", "_nodeCount" ];

_rope  = _this select 0;
_nodes = _rope select 0;

_nodeCount = count _nodes;

// Not using any call function statements because they slowed the computation down
// this makes it less readable

//
// Define function for cross product
//

// According to docs, while loop iterations are limited, using for instead

for [{;}, {true}, {;}] do
{
    private [ "_deltaTime", "_deltaTime2" ];
    
    _deltaTime  = _rope select HEDU_ROPE_DELTA_TIME_INDEX;
    _deltaTime2 = _deltaTime * _deltaTime;

    //
    // Split rope into equal segments
    //
    
    private [ "_i" ];

    for [{_i = 1}, {_i < _nodeCount}, {_i = _i + 1}] do
    {
        private [ "_current" ];
        
        _current = _nodes select _i;
        
        _current set [HEDU_ROPE_NODE_DISTANCE_TO_PREVIOUS_INDEX, (_rope select HEDU_ROPE_LENGTH_INDEX) / (_nodeCount - 1)];
    };

    //
    // What follows are two passes over all nodes.
    // The passes are less readable because of attempts to speedup computation and therefore contain no function calls and
    // weird control structure.
    //

    //
    // First pass, compute spring forces, positions, acceleration, velocity, current drag, ...
    //
        
    for [{_i = 0}, {_i < _nodeCount}, {_i = _i + 1}] do
    {    
        private [ "_current" ];
    
        _current = _nodes select _i;
    
        //
        // Compute spring forces
        //
        
        private [ "_force" ];
        
        _force = [0.0, 0.0, 0.0];


        // If not the first node
        
        if (_i > 0) then
        {
            //
            // Add force to previous node 
            //
            
            private [ "_neighbor", "_neighborPosition", "_forceToNeighbor" ];
            
            _neighbor = _nodes select (_i - 1);
            
            private [ "_currentPosition", "_neighborPosition" ];
                    
            _currentPosition  = _current  select HEDU_ROPE_NODE_POSITION_1_INDEX;
            _neighborPosition = _neighbor select HEDU_ROPE_NODE_POSITION_1_INDEX;

            private [ "_offset", "_distance" ];
            
            _offset = [ (_neighborPosition select 0) - (_currentPosition select 0),
                        (_neighborPosition select 1) - (_currentPosition select 1),
                        (_neighborPosition select 2) - (_currentPosition select 2) ];

            _distance = sqrt ( ((_offset select 0) * (_offset select 0)) +
                               ((_offset select 1) * (_offset select 1)) + 
                               ((_offset select 2) * (_offset select 2))  );
   
            _forceToNeighbor = [0.0, 0.0, 0.0];
   
            if (_distance > 0.0001) then
            {
                private [ "_offsetNormalized", "_delta", "_k", "_factor" ];
            
                _offsetNormalized = [ (_offset select 0) / _distance, (_offset select 1) / _distance, (_offset select 2) / _distance ];
                                
                _delta = _distance - (_current select HEDU_ROPE_NODE_DISTANCE_TO_PREVIOUS_INDEX);
                
                _k = _current select HEDU_ROPE_NODE_SPRING_FACTOR_INDEX;
                
                _factor = _k * _delta;
                
                _forceToNeighbor = [  (_offsetNormalized select 0) * _factor,
                            (_offsetNormalized select 1) * _factor,
                            (_offsetNormalized select 2) * _factor ];
            };
            
            _force = [  (_force select 0) + (_forceToNeighbor select 0),
                        (_force select 1) + (_forceToNeighbor select 1),
                        (_force select 2) + (_forceToNeighbor select 2) ];
     
        };
        
        // If not the last node
        
        if ( _i <= _nodeCount - 1 ) then
        { 
            //
            // Add force to next node
            //
                        
            private [ "_neighbor", "_neighborPosition", "_forceToNeighbor" ];
            
            _neighbor = _nodes select (_i + 1);
            
            private [ "_currentPosition", "_neighborPosition" ];
                    
            _currentPosition  = _current  select HEDU_ROPE_NODE_POSITION_1_INDEX;
            _neighborPosition = _neighbor select HEDU_ROPE_NODE_POSITION_1_INDEX;

            private [ "_offset", "_distance" ];
            
            _offset = [ (_neighborPosition select 0) - (_currentPosition select 0),
                        (_neighborPosition select 1) - (_currentPosition select 1),
                        (_neighborPosition select 2) - (_currentPosition select 2) ];

            _distance = sqrt ( ((_offset select 0) * (_offset select 0)) +
                               ((_offset select 1) * (_offset select 1)) + 
                               ((_offset select 2) * (_offset select 2))  );
   
            _forceToNeighbor = [0.0, 0.0, 0.0];
   
            if (_distance > 0.0001) then
            {
                private [ "_offsetNormalized", "_delta", "_k", "_factor" ];
            
                _offsetNormalized = [ (_offset select 0) / _distance, (_offset select 1) / _distance, (_offset select 2) / _distance ];
                                
                _delta = _distance - (_current select HEDU_ROPE_NODE_DISTANCE_TO_PREVIOUS_INDEX);
                
                _k = _current select HEDU_ROPE_NODE_SPRING_FACTOR_INDEX;
                
                _factor = _k * _delta;
                
                _forceToNeighbor = [  (_offsetNormalized select 0) * _factor,
                            (_offsetNormalized select 1) * _factor,
                            (_offsetNormalized select 2) * _factor ];
            };
            
            _force = [  (_force select 0) + (_forceToNeighbor select 0),
                        (_force select 1) + (_forceToNeighbor select 1),
                        (_force select 2) + (_forceToNeighbor select 2) ];
        };
        
        _current set [HEDU_ROPE_NODE_FORCE_INDEX, _force];

            
        //
        // Compute position from forces
        //
        
        private [ "_position0", "_position1", "_velocity1", "_mass" ];

        _position0  = _current select HEDU_ROPE_NODE_POSITION_0_INDEX;
        _position1  = _current select HEDU_ROPE_NODE_POSITION_1_INDEX;
        _velocity1  = _current select HEDU_ROPE_NODE_VELOCITY_INDEX;
        _mass       = _current select HEDU_ROPE_NODE_MASS_INDEX;

        //
        // Add air drag
        //
        
        private [ "_speed" ];

        _speed = sqrt ( ((_velocity1 select 0) * (_velocity1 select 0)) +
                        ((_velocity1 select 1) * (_velocity1 select 1)) +
                        ((_velocity1 select 2) * (_velocity1 select 2))   );
        
        if (_speed > 0.0) then
        {
            private [ "_normalizedVelocity", "_drag", "_squaredSpeedTimesDrag" ];
            
            _normalizedVelocity = [ (_velocity1 select 0) / _speed,
                                    (_velocity1 select 1) / _speed,
                                    (_velocity1 select 2) / _speed ];

            _drag = _current select HEDU_ROPE_NODE_DRAG_INDEX;
            
            _squaredSpeedTimesDrag = _speed * _speed * _drag;
        
            _force = [ (_force select 0) - (_squaredSpeedTimesDrag * (_normalizedVelocity select 0)),
                       (_force select 1) - (_squaredSpeedTimesDrag * (_normalizedVelocity select 1)),
                       (_force select 2) - (_squaredSpeedTimesDrag * (_normalizedVelocity select 2))  ];
        };
        
        // Add gravity force
    
        _force set [2, (_force select 2) - (9.81 * _mass) ];
        
        // Compute acceleration
        
        private [ "_acceleration" ];
        
        _acceleration = [   (_force select 0) / _mass,
                            (_force select 1) / _mass,
                            (_force select 2) / _mass ];
                            
        private [ "_currentATL", "_terrainHeight", "_seaHeight", "_terrainToSeaDifference" ];
                        
        _currentATL = getPosATL (_current select HEDU_ROPE_NODE_OBJECT_INDEX);
        
        _terrainHeight = _currentATL select 2;
        _seaHeight     = _position1  select 2;
        
        _terrainToSeaDifference = _seaHeight - _terrainHeight;

        private [ "_damping" ];
        
        _damping = _current select HEDU_ROPE_NODE_DAMPING_INDEX;
        
        // If under/on ground
        
        private [ "_groundHeightOffset" ];
        
        _groundHeightOffset = _current select HEDU_ROPE_NODE_GROUND_OFFSET_INDEX;
        
        if (_terrainHeight <= _groundHeightOffset) then
        {
            _acceleration  set [2, 0.0 max (_acceleration select 2)];
            _position0 set [2, _terrainToSeaDifference + _groundHeightOffset];
            _position1 set [2, _terrainToSeaDifference + _groundHeightOffset];
            
            _damping = HEDU_ROPE_NODE_TERRAIN_DAMPING;
            
            _current set [HEDU_ROPE_NODE_IS_ON_GROUND_INDEX, true];
        }
        else
        {
            _current set [HEDU_ROPE_NODE_IS_ON_GROUND_INDEX, false];
        };

        // If under/on water
        
        private [ "_seaHeightOffset" ];
        
        _seaHeightOffset = _current select HEDU_ROPE_NODE_SEA_OFFSET_INDEX;
        
        if (_seaHeight <= _seaHeightOffset) then
        {
            // If the node can float
            
            if ( _current select HEDU_ROPE_NODE_CAN_FLOAT_INDEX ) then
            {
                _acceleration  set [ 2, 0.0 max (_acceleration select 2) ];
                _position0 set [ 2, _seaHeightOffset ];
                _position1 set [ 2, _seaHeightOffset ];
            };
            
            _damping = HEDU_ROPE_NODE_SEA_DAMPING;
            
            _current set [HEDU_ROPE_NODE_IS_ON_OR_UNDER_WATER_INDEX, true];
        }
        else
        {
            _current set [HEDU_ROPE_NODE_IS_ON_OR_UNDER_WATER_INDEX, false];
        };
        
        // Update position    
        
        private [ "_doUpdate" ];
        
        _doUpdate = _current select HEDU_ROPE_NODE_DO_UPDATE_INDEX;

        private [ "_position2" ];
        
        if (_doUpdate) then
        {    
            _position2 = [  ((2 - _damping) * (_position1 select 0)) - ((1 - _damping) * (_position0 select 0)) + ((_acceleration select 0) * _deltaTime2),
                            ((2 - _damping) * (_position1 select 1)) - ((1 - _damping) * (_position0 select 1)) + ((_acceleration select 1) * _deltaTime2),
                            ((2 - _damping) * (_position1 select 2)) - ((1 - _damping) * (_position0 select 2)) + ((_acceleration select 2) * _deltaTime2) ];                       
        }
        else
        {                      
            // Update node position from object position
            
            _position2 = getPosASL (_current select HEDU_ROPE_NODE_OBJECT_INDEX);
        };
        
        // Update velocity
        
        private [ "_velocity2" ];
        
        _velocity2 = [  ((_position2 select 0) - (_position1 select 0)) / _deltaTime,
                        ((_position2 select 1) - (_position1 select 1)) / _deltaTime,
                        ((_position2 select 2) - (_position1 select 2)) / _deltaTime  ];
        
        _current set [HEDU_ROPE_NODE_POSITION_0_INDEX, _position1];
        _current set [HEDU_ROPE_NODE_POSITION_1_INDEX, _position2];
        _current set [HEDU_ROPE_NODE_VELOCITY_INDEX,   _velocity2];
    };
    
    //
    // Second pass, apply distance constraints and fix positions, rotate nodes and set visible segment length.
    // Iterate over pairs of nodes.
    //
        
    for [{_i = 0}, {_i < _nodeCount - 1}, {_i = _i + 1}] do
    {    
        private [ "_node0", "_node1" ];
        
        //
        // Pair-wise apply distance constraint to current and next node
        //

        _node0 = _nodes select _i;
        _node1 = _nodes select (_i + 1);
        
        private [ "_doUpdate0", "_doUpdate1" ];
        
        _doUpdate0 = _node0 select HEDU_ROPE_NODE_DO_UPDATE_INDEX;
        _doUpdate1 = _node1 select HEDU_ROPE_NODE_DO_UPDATE_INDEX;
        
        private [ "_posNode0", "_posNode1" ];
        
        _posNode0 = _node0 select HEDU_ROPE_NODE_POSITION_1_INDEX;
        _posNode1 = _node1 select HEDU_ROPE_NODE_POSITION_1_INDEX;
        
        private [ "_difference", "_distance", "_percent" ];
        
        _difference = [ (_posNode1 select 0) - (_posNode0 select 0),
                        (_posNode1 select 1) - (_posNode0 select 1),
                        (_posNode1 select 2) - (_posNode0 select 2) ];
            
        _distance = sqrt ( ((_difference select 0) * (_difference select 0)) +
                           ((_difference select 1) * (_difference select 1)) + 
                           ((_difference select 2) * (_difference select 2))  );

        _percent = (_distance - (_node1 select HEDU_ROPE_NODE_DISTANCE_TO_PREVIOUS_INDEX)) / _distance;
        
        private [ "_currentATL0", "_currentATL1", "_groundHeight0", "_groundHeight1" ];
        
        _currentATL0 = getPosATL (_node0 select HEDU_ROPE_NODE_OBJECT_INDEX);
        _groundHeight0 = _currentATL0 select 2;
        
        _currentATL1 = getPosATL (_node1 select HEDU_ROPE_NODE_OBJECT_INDEX);
        _groundHeight1 = _currentATL1 select 2;

        private [ "_newPositionNode0", "_newPositionNode1" ];
        
        _newPositionNode0 = objNull;
        _newPositionNode1 = objNull;
        
        // If pushing nodes apart
        
        if (_percent < 0.0) then
        {
            // If above ground (don't push into ground)
            
            if (_groundHeight0 > 0.0) then
            {
                if (_doUpdate1) then
                {
                    _newPositionNode0 = [   (_posNode0 select 0) + (0.5 * (_difference select 0) * _percent), 
                                            (_posNode0 select 1) + (0.5 * (_difference select 1) * _percent),
                                            (_posNode0 select 2) + (0.5 * (_difference select 2) * _percent) ];
                }
                else
                {
                    // Add complete offset

                    _newPositionNode0 = [   (_posNode0 select 0) + (1 * (_difference select 0) * _percent), 
                                            (_posNode0 select 1) + (1 * (_difference select 1) * _percent),
                                            (_posNode0 select 2) + (1 * (_difference select 2) * _percent) ];                
                };
                    
                if (_doUpdate0) then
                {
                    _node0 set [HEDU_ROPE_NODE_POSITION_1_INDEX, _newPositionNode0];    
                };
            };
            
            // If above ground (don't push into ground)
            
            if (_groundHeight1 > 0.0) then
            {
                if (_doUpdate0) then
                {
                    _newPositionNode1 = [   (_posNode1 select 0) - (0.5 * (_difference select 0) * _percent), 
                                            (_posNode1 select 1) - (0.5 * (_difference select 1) * _percent),
                                            (_posNode1 select 2) - (0.5 * (_difference select 2) * _percent) ];                
                }
                else
                {
                    // Add complete offset

                    _newPositionNode1 = [   (_posNode1 select 0) - (1 * (_difference select 0) * _percent), 
                                            (_posNode1 select 1) - (1 * (_difference select 1) * _percent),
                                            (_posNode1 select 2) - (1 * (_difference select 2) * _percent) ];    
                };
                
                if (_doUpdate1) then
                {
                    _node1 set [HEDU_ROPE_NODE_POSITION_1_INDEX, _newPositionNode1];
                };
            };
        }
        // If pulling nodes together
        else
        {
            if (_doUpdate1) then
            {
                _newPositionNode0 = [   (_posNode0 select 0) + (0.5 * (_difference select 0) * _percent), 
                                        (_posNode0 select 1) + (0.5 * (_difference select 1) * _percent),
                                        (_posNode0 select 2) + (0.5 * (_difference select 2) * _percent) ];
            }
            else
            {
                // Add complete offset
                
                _newPositionNode0 = [   (_posNode0 select 0) + (1 * (_difference select 0) * _percent), 
                                        (_posNode0 select 1) + (1 * (_difference select 1) * _percent),
                                        (_posNode0 select 2) + (1 * (_difference select 2) * _percent) ];
            };
            
            if (_doUpdate0) then
            {
                _node0 set [HEDU_ROPE_NODE_POSITION_1_INDEX, _newPositionNode0];                                 
            };    
                    
            if (_doUpdate0) then
            {
                _newPositionNode1 = [   (_posNode1 select 0) - (0.5 * (_difference select 0) * _percent), 
                                        (_posNode1 select 1) - (0.5 * (_difference select 1) * _percent),
                                        (_posNode1 select 2) - (0.5 * (_difference select 2) * _percent) ];                
            }
            else
            {
                // Add complete offset
                
                _newPositionNode1 = [   (_posNode1 select 0) - (1 * (_difference select 0) * _percent), 
                                        (_posNode1 select 1) - (1 * (_difference select 1) * _percent),
                                        (_posNode1 select 2) - (1 * (_difference select 2) * _percent) ];
            };
            
            if (_doUpdate1) then
            {
                _node1 set [HEDU_ROPE_NODE_POSITION_1_INDEX, _newPositionNode1];
            };                
        };


        //
        // Update object position
        //

        private [ "_node0Object" ];
        
        _node0Object = _node0 select HEDU_ROPE_NODE_OBJECT_INDEX;
    
        _newPositionNode0 = _node0 select HEDU_ROPE_NODE_POSITION_1_INDEX;
    
        if (_doUpdate0) then
        {
            _node0Object setPosASL _newPositionNode0;
        };
        
        // If not first node
        
        if (_i > 0) then
        {
            //
            // Rotate node
            //
            
            private [ "_previous", "_previousNodePosition" ];
            
            _previous = _nodes select (_i - 1);
            _previousNodePosition = _previous select HEDU_ROPE_NODE_POSITION_1_INDEX;

            if (!_doUpdate0) then
            {
                // Compute direction in model space because attached objects rotate differently
                
                _previousNodePosition = (_node0 select HEDU_ROPE_NODE_ATTACHMENT_OBJECT_INDEX) worldToModel _previousNodePosition;
                _newPositionNode0 = (_node0 select HEDU_ROPE_NODE_ATTACHMENT_OBJECT_INDEX) worldToModel _newPositionNode0;
            };
            
            private [ "_tempVector", "_direction", "_up" ];
            
            _up = [    (_previousNodePosition select 0) - (_newPositionNode0 select 0),
                    (_previousNodePosition select 1) - (_newPositionNode0 select 1),
                    (_previousNodePosition select 2) - (_newPositionNode0 select 2) ];
            
            _tempVector = +_up;
            _tempVector set [2, (_tempVector select 2) + 0.0001];
            
            // Compute cross product
            
            private [   "_a", "_aX", "_aY", "_aZ",
                        "_b", "_bX", "_bY", "_bZ" ];

            _a = _up;

            _aX = _a select 0;
            _aY = _a select 1;
            _aZ = _a select 2;

            _b = _tempVector;

            _bX = _b select 0;
            _bY = _b select 1;
            _bZ = _b select 2;
            
            _direction = [  _aY * _bZ - _aZ * _bY,
                            _aZ * _bX - _aX * _bZ,
                            _aX * _bY - _aY * _bX ];
             
            _node0Object setVectorDirAndUp [_direction, _up];
            
            //                
            // Animate length
            //
            
            _node0Object animate [ _node0 select HEDU_ROPE_NODE_ANIMATION_NAME_INDEX, _node0 select HEDU_ROPE_NODE_DISTANCE_TO_PREVIOUS_INDEX ];
        };
            
        // If we are the node before the last one, also handle the last node
        
        if (_i == _nodeCount - 2) then
        {
            //
            // Update object position
            //

            private [ "_node1Object" ];
                    
            _node1Object = _node1 select HEDU_ROPE_NODE_OBJECT_INDEX;
            
            _newPositionNode1 = _node1 select HEDU_ROPE_NODE_POSITION_1_INDEX;
        
            if (_doUpdate1) then
            {
                _node1Object setPosASL _newPositionNode1;
            };
            
            //
            // Rotate node
            //
            
            // Retrieve position again, might have been changed to local position above
            
            _newPositionNode0 = _node0 select HEDU_ROPE_NODE_POSITION_1_INDEX;
            
            if (!_doUpdate1) then
            {
                // Compute direction in model space because attached objects rotate differently
                
                _newPositionNode0 = (_node1 select HEDU_ROPE_NODE_ATTACHMENT_OBJECT_INDEX) worldToModel _newPositionNode0;
                _newPositionNode1 = (_node1 select HEDU_ROPE_NODE_ATTACHMENT_OBJECT_INDEX) worldToModel _newPositionNode1;
            };
            
            private [ "_tempVector", "_direction", "_up" ];
            
            _up = [ (_newPositionNode0 select 0) - (_newPositionNode1 select 0),
                    (_newPositionNode0 select 1) - (_newPositionNode1 select 1),
                    (_newPositionNode0 select 2) - (_newPositionNode1 select 2) ];

            _tempVector = +_up;
            _tempVector set [2, (_tempVector select 2) + 0.0001];
                        
            // Compute cross product
            
            private [   "_a", "_aX", "_aY", "_aZ",
                        "_b", "_bX", "_bY", "_bZ" ];

            _a = _up;

            _aX = _a select 0;
            _aY = _a select 1;
            _aZ = _a select 2;

            _b = _tempVector;

            _bX = _b select 0;
            _bY = _b select 1;
            _bZ = _b select 2;
            
            _direction = [  _aY * _bZ - _aZ * _bY,
                            _aZ * _bX - _aX * _bZ,
                            _aX * _bY - _aY * _bX ];
                            
            _node1Object setVectorDirAndUp [_direction, _up];
            
            //                
            // Animate length
            //
            
            _node1Object animate [ _node1 select HEDU_ROPE_NODE_ANIMATION_NAME_INDEX, _node1 select HEDU_ROPE_NODE_DISTANCE_TO_PREVIOUS_INDEX ];
        };
    };

    sleep (_rope select HEDU_ROPE_SLEEP_TIME_INDEX);
};