/**************************************************************************
**
**   SNOW - CS224 BROWN UNIVERSITY
**
**   collider.cu
**   Authors: evjang, mliberma, taparson, wyegelwe
**   Created: 17 Apr 2014
**
**************************************************************************/


#include <cuda.h>
#include <cuda_runtime.h>

#ifndef GLM_FORCE_RADIANS
    #define GLM_FORCE_RADIANS
#endif
#include <glm/geometric.hpp>

#include "math.h"   // this imports the CUDA math library
#include "sim/collider.h"
#include "matrix.cu"
#include "vector.cu"

// isColliding functions
typedef bool (*isCollidingFunc) (const ImplicitCollider &collider, const vec3 &position);

/**
 * A collision occurs when the point is on the OTHER side of the normal
 */
__device__ bool isCollidingHalfPlane(const vec3 &planePoint, const vec3 &planeNormal, const vec3 &position){
    vec3 vecToPoint = position - planePoint;
    return (vec3::dot(vecToPoint, planeNormal) <= 0);
}

/**
 * Defines a halfplane such that collider.center is a point on the plane,
 * and collider.param is the normal to the plane.
 */
__device__ bool isCollidingHalfPlaneImplicit(const ImplicitCollider &collider, const vec3 &position){
    return isCollidingHalfPlane(collider.center, collider.param, position);
}

/**
 * Defines a sphere such that collider.center is the center of the sphere,
 * and collider.param.x is the radius.
 */
__device__ bool isCollidingSphereImplicit(const ImplicitCollider &collider, const vec3 &position){
    float radius = collider.param.x;
    return (vec3::length(position-collider.center) <= radius);
}


/** array of colliding functions. isCollidingFunctions[collider.type] will be the correct function */
__device__ isCollidingFunc isCollidingFunctions[2] = {isCollidingHalfPlaneImplicit, isCollidingSphereImplicit};


/**
 * General purpose function for handling colliders
 */
__device__ bool isColliding(const ImplicitCollider &collider, const vec3 &position){
    return isCollidingFunctions[collider.type](collider, position);
}


// colliderNormal functions

/**
 * Returns the (normalized) normal of the collider at the position.
 * Note: this function does NOT check that there is a collision at this point, and behavior is undefined if there is not.
 */
typedef void (*colliderNormalFunc) (const ImplicitCollider &collider, const vec3 &position, vec3 &normal);

__device__ void colliderNormalSphere(const ImplicitCollider &collider, const vec3 &position, vec3 &normal){
    normal = vec3::normalize(position - collider.center);
}

__device__ void colliderNormalHalfPlane(const ImplicitCollider &collider, const vec3 &position, vec3 &normal){
    normal = collider.param; //The halfplanes normal is stored in collider.param
}

/** array of colliderNormal functions. colliderNormalFunctions[collider.type] will be the correct function */
__device__ colliderNormalFunc colliderNormalFunctions[2] = {colliderNormalHalfPlane, colliderNormalSphere};

__device__ void colliderNormal(const ImplicitCollider &collider, const vec3 &position, vec3 &normal){
    colliderNormalFunctions[collider.type](collider, position, normal);
}

__device__ void checkForAndHandleCollisions(ImplicitCollider *colliders, int numColliders, float coeffFriction, const vec3 &position, vec3 &velocity ){
    for (int i = 0; i < numColliders; i++){
        ImplicitCollider &collider = colliders[i];
        if (isColliding(collider, position)){
            vec3 vRel = velocity - collider.velocity;
            vec3 normal;
            colliderNormal(collider, position, normal);
            float vn = vec3::dot(vRel, normal);
            if (vn < 0 ){ //Bodies are not separating and a collision must be applied
                vec3 vt = vRel - normal*vn;
                float magVt = vec3::length(vt);
                if (magVt <= -coeffFriction*vn){ // tangential velocity not enough to overcome force of friction
                    vRel = vec3(0.0f);
                } else{
                    vRel = (1+coeffFriction*vn/magVt)*vt;
                }
            }
            velocity = vRel + collider.velocity;
        }
    }
}
