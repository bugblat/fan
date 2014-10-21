#ifndef GPROXY_H
#define GPROXY_H

#include "gexport.h"
#include "greferenced.h"

class GIDEROS_API GProxy : public GReferenced
{
protected:
	enum GType
	{
		eBase,
		eEventDispatcher,
		eSprite,
	};

public:
	GProxy(GType type = eBase);
	virtual ~GProxy();

	GReferenced* object() const
	{
		return object_;
	}

protected:
	GReferenced* object_;
};

class GIDEROS_API GEventDispatcherProxy : public GProxy
{
public:
	GEventDispatcherProxy(GType type = eEventDispatcher);
	virtual ~GEventDispatcherProxy();
};

class GIDEROS_API GSpriteProxy : public GEventDispatcherProxy
{
public:
	GSpriteProxy(GType type = eSprite);
	virtual ~GSpriteProxy();
};

#endif
