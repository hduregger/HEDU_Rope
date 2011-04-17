#include "HEDU_Rope.hpp"

private [ "_nodeCount", "_position", "_startLength" ];
            
_nodeCount   = _this select 0;
_position    = _this select 1;
_startLength = _this select 2;

if (_nodeCount < 2) then
{
    _nodeCount = 2;
};

if (_startLength < 0.0) then
{
    _startLength = 0.0;
};

private [ "_spacing", "_nodes", "_i" ];

_spacing = _startLength / _nodeCount;

_nodes = [];

for [{_i = 0}, {_i < _nodeCount}, {_i = _i + 1}] do
{
    private [ "_positionTemp", "_ropeMesh", "_node" ];
    
    _positionTemp = [ _position select 0,
                      _position select 1,
                      (_position select 2) - _i * _spacing ];
    
    _ropeMesh = "HEDU_Rope" createVehicle _positionTemp;
        
    _node = [ _ropeMesh,
              _positionTemp,
              _positionTemp,
              [0.0, 0.0, 0.0],
              [0.0, 0.0, 0.0],
              _spacing,
              HEDU_ROPE_NODE_MASS,
              false,
              false,
              false,
              [0.0, 0.0, 0.0],
              objNull,
              0.0,
              HEDU_ROPE_NODE_DRAG,
              HEDU_ROPE_NODE_SPRING_FACTOR,
              HEDU_ROPE_NODE_ANIMATION_NAME,
              false,
              0.0,
              0.0                            ];

    _nodes = _nodes + [+_node];
    
    _ropeMesh setPosASL _positionTemp;
};

[ _nodes, _startLength, HEDU_ROPE_DELTA_TIME, HEDU_ROPE_SLEEP_TIME ]
