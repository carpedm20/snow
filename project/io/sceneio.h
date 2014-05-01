/**************************************************************************
**
**   SNOW - CS224 BROWN UNIVERSITY
**
**   sceneparser.h
**   Authors: evjang, mliberma, taparson, wyegelwe
**   Created: 14 Apr 2014
**
**************************************************************************/

#ifndef SCENEIO_H
#define SCENEIO_H

/**
 * @brief SceneIO class
 *
 * reads/writes scene files. Scene files contain not only static objects,
 * but the snow simulation parameters.
 * doubles as save file format and blender import format
 *
 * Note, this is designed to be saved once when beginning a simulation with exporting
 * enabled, so this class was not designed with multithreading in mind.
 *
 */

#include <iostream>
#include <QtXml>
#include "glm/mat4x4.hpp"

struct vec3;

struct SimulationParameters;
struct ImplicitCollider;

class Scene;
class Engine;
class Grid;
class ParticleSystem;

class SceneIO
{
public:
    SceneIO();

    bool read(QString fname, Scene * scene, Engine * engine);
    bool write(Scene * scene, Engine * engine);

    QString sceneFile() { return m_sceneFilePrefix; }
    void setSceneFile(QString filename);

private:
    QString m_sceneFilePrefix;
    QDomDocument m_document; // XML document

    /// importing

    void readExportSettings();

    // TODO - add methods for parsing a file and setting up the scene.

    /// high-level XML functions

    void appendSimulationParameters(SimulationParameters params);
    void appendParticleSystem(Scene * scene);
    void appendGrid(Grid grid);
    void appendColliders(QVector<ImplicitCollider> colliders);
    void appendExportSettings();

    /// low level DOM node helpers
    void appendString(QDomElement node, const QString name, const QString value);
    void appendInt(QDomElement node, const QString name, const int i);
    void appendFloat(QDomElement node, const QString name, const float f);
    void appendVector(QDomElement node, const QString name, const vec3 v);
    void appendDim(QDomElement node, const QString name, const glm::ivec3 iv);
    void appendMatrix(QDomElement node, const QString name, const glm::mat4 mat);
};

#endif // SCENEIO_H
