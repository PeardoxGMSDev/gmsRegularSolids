function pdxVec2(x = 0, y=0) constructor {
    self.x = x;
    self.y = y;    

    static set = function(x = 0, y=0) {
        self.x = x;
        self.y = y;
   }
    
    static add = function(x = 0, y=0) {
        self.x += x;
        self.y += y;
   }
    
    static isChanged = function() {
        if(self.x != 0) {
            return true;
        }
        if(self.y != 0) {
            return true;
        }
            
        return false;
    }
    
    
}


function pdxVec3(x = 0, y=0, z=0) : pdxVec2(x, y) constructor {
    self.z = z;

    static set = function(x = 0, y=0, z=0) {
        self.x = x;
        self.y = y;
        self.z = z;
   }
    
    static add = function(x = 0, y=0, z=0) {
        self.x += x;
        self.y += y;
        self.z += z;
   }
    
    static isChanged = function() {
        if(self.x != 0) {
            return true;
        }
        if(self.y != 0) {
            return true;
        }
        if(self.z != 0) {
            return true;
        }
            
        return false;
    }

}

function pdxVec4(x = 0, y=0, z=0, w = 1) : pdxVec3(x, y, z) constructor {
    self.w = w;
    
    static set = function(x = 0, y=0, z=0, w = 1) {
        self.x = x;
        self.y = y;
        self.z = z;
        self.w = w;
   }
    
    static add = function(x = 0, y=0, z=0, w = 1) {
        self.x += x;
        self.y += y;
        self.z += z;
        self.w += w;
   }

    static isChanged = function() {
        if(self.x != 0) {
            return true;
        }
        if(self.y != 0) {
            return true;
        }
        if(self.z != 0) {
            return true;
        }
        if(self.w != 1) {
            return true;
        }
            
        return false;
    }
}

function pdxTransform() constructor {
    self.translation = new pdxVec3();
    self.rotation    = new pdxVec4();
    self.scale       = new pdxVec3();
    
    static setTranslation = function(x = 0, y = 0, z = 0) {
        self.translation.set(x, y, z);
    }

    static setRotation = function(x = 0, y = 0, z = 0, w = 0) {
        self.rotation.set(x, y, z, w);
    }

    static setScale = function(x = 0, y = 0, z = 0) {
        self.scale.set(x, y, z);
    }

    static addTranslation = function(x = 0, y = 0, z = 0) {
        self.translation.add(x, y, z);
    }

    static addRotation = function(x = 0, y = 0, z = 0, w = 1) {
        self.rotation.add(x, y, z, w);
    }

    static addScale = function(x = 0, y = 0, z = 0) {
        self.scale.add(x, y, z);
    }
    
    static isChanged = function() {
        if(self.translation.isChanged()) {
            return true;
        }
        if(self.rotation.isChanged()) {
            return true;
        }
        if(self.scale.isChanged()) {
            return true;
        }
    }

}

function pdxUV(u = 0, v = 0) constructor {
    self.u = u;
    self.v = v;    
}

function pdxModel() constructor {
    self.vertices       = [];
    self.faces          = [];
    self.normals        = [];
    self.uvs            = [];
    self.labels         = [];
    self.texture        = -1;
    self.vertexBuffer   = undefined;
    self.transform      = new pdxTransform();
    self.children       = [];
    self.isRoot         = true;

    /// @function addChild
    /// @description Add a child to this model
    /// @param {Struct.pdxModel} child child model
    addChild = function(child = undefined) {
     
        if(is_instanceof(child, pdxModel)) {
            child.isRoot = false;
            array_push(self.children, child);
        }
        
        return child;
    }
    
    
    static setTranslation = function(x = 0, y = 0, z = 0) {
        self.transform.setTranslation(x, y, z);
    }

    static setRotation = function(x = 0, y = 0, z = 0, w = 1) {
        self.transform.setRotation(x, y, z, w);
    }

    static setScale = function(x = 0, y = 0, z = 0) {
        self.transform.setScale(x, y, z);
    }
    
    /// @function draw_octahedron
    /// @description Draw octahedron using vertex buffer
    static draw = function() {
        /*
        if(self.transform.isChanged()) {
            var matrix = matrix_build(self.transform.translation.x, self.transform.translation.y, self.transform.translation.z,
                self.transform.rotation.x, self.transform.rotation.y, self.transform.rotation.z, 
                self.transform.scale.x,self.transform.scale.y,self.transform.scale.z);
            matrix_set(matrix_world, matrix);
            vertex_submit(self.vertexBuffer, pr_trianglelist, self.texture);
            matrix_set(matrix_world, matrix_build_identity());
        } else {
            vertex_submit(self.vertexBuffer, pr_trianglelist, self.texture);
        }
        for(var i = 0, c = array_length(self.children); i < c; i++) {
            self.children[i].draw();
        }
        */
        vertex_submit(self.vertexBuffer, pr_trianglelist, self.texture);
    }    
    
    static boundsa = function() {
        var vmin = new pdxVec3(infinity, infinity, infinity);
        var vmax = new pdxVec3(-infinity, -infinity, -infinity);
        
        for(var i = 0, c = array_length(self.vertices); i < c; i++) {
            if(vmin.x > self.vertices[i][0]) {
                vmin.x = self.vertices[i][0];
            }
            if(vmin.y > self.vertices[i][1]) {
                vmin.y = self.vertices[i][1];
            }
            if(vmin.z > self.vertices[i][2]) {
                vmin.z = self.vertices[i][2];
            }
            if(vmax.x < self.vertices[i][0]) {
                vmax.x = self.vertices[i][0];
            }
            if(vmax.y < self.vertices[i][1]) {
                vmax.y = self.vertices[i][1];
            }
            if(vmax.z < self.vertices[i][2]) {
                vmax.z = self.vertices[i][2];
            }
        }
        
        return { min: vmin, max: vmax };
    }
    
    static bounds = function() {
        var vmin = new pdxVec3( infinity,  infinity,  infinity);
        var vmax = new pdxVec3(-infinity, -infinity, -infinity);

        for (var i = 0, c = array_length(self.vertices); i < c; i++) {
            var v = self.vertices[i];
            if (vmin.x > v.x) vmin.x = v.x;
            if (vmin.y > v.y) vmin.y = v.y;
            if (vmin.z > v.z) vmin.z = v.z;
            if (vmax.x < v.x) vmax.x = v.x;
            if (vmax.y < v.y) vmax.y = v.y;
            if (vmax.z < v.z) vmax.z = v.z;
        }

        return { min: vmin, max: vmax };
    }
}

function Model() : pdxModel() constructor {

}
    

