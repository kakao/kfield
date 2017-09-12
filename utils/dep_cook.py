#!/usr/bin/python
 
# Script for extracting dependencies from chefcookbook repositories.
# Hugh Saunders 2013
 
# The output is "item,depdency" one pair per line. The idea is to then graph these with Gegpih (https://gephi.org/)
# There are three methods for working out dependencies see -h or the argparse section in main()
# If you wish to use the cookbook metadata option, use:
#      knife cookbook metadata -o cookbook-dir --all
# to generate the json files.
 
import sys
import os
import json
import re
import argparse
 
 
class Cookbook:
    """Class representing a cookbook.
    This is used when basing dependencies on cookbook metadata.
    There is a class attribute list to keep track of instances."""
    cookbooks = []
 
    def __init__(self, file_path):
        self.json = json.load(open(file_path, 'r'))
        Cookbook.cookbooks.append(self)
 
    def get_deps(self):
        return self.json['dependencies'].keys()
 
    def get_name(self):
        return self.json['name']
 
    @classmethod
    def get_all_cookbook_deps(cls):
        return_list = []
        for cookbook in cls.cookbooks:
            for dep in cookbook.get_deps():
                return_list.append((cookbook.get_name(), dep))
        return return_list
 
 
class GetDeps:
    def __init__(self, start_dir):
        self.start_dir = start_dir
 
    def process_chef_repo(self, start_dir=None):
        if not start_dir:
            start_dir = self.start_dir
        for directory, folders, files in os.walk(start_dir):
            if 'metadata.json' in files:
                Cookbook(os.path.join(directory, 'metadata.json'))
            elif directory.split(os.sep)[-1] == 'recipes':
                for recipe_file in [f for f in files if re.search('\.rb$', f)]:
                    recipe = Recipe.recipe_from_path(os.path.join(directory, recipe_file))
                    recipe.process_recipe()
            elif directory.split(os.sep)[-1] == 'roles':
                for role_file in [f for f in files if re.search('\.rb$', f)]:
                    role = Role.role_from_path(os.path.join(directory, role_file))
                    role.process_role()
 
 
class Recipe:
    recipes = {}
    #(?:...) == non capturing group
    #(?P<name>...) = named capture group
    name_re = re.compile(r'(?:(?P<cookbook>[^:]+)(?:::))?(?P<recipe_name>.+)?')
 
    def __init__(self, name):
        self.name = name
        self.file_path = None
        self.dep_roles = []
        self.dep_recipes = []
        Recipe.recipes[self.name] = self
 
    @classmethod
    def name_from_path(cls, path):
        path_array = path.split(os.sep)
        recipes_index = path_array.index('recipes')
        cookbook = path_array[recipes_index - 1]
        recipe_name = path_array[recipes_index + 1].split('.')[0]
        name = '%s::%s' % (cookbook, recipe_name)
        return name, recipe_name, cookbook
 
    def process_recipe(self):
        """A recicpe is dependent on another recipe if it includes it.
        A recipe is dependent on a role if it calls get_*_endpoint(Role,_,_)"""
        assert self.file_path
        #endpoint_re = re.compile(r'get_(?:lb|access)_endpoint\(["\'\s]*([^"\']+)["\'],')
        endpoint_re = re.compile(r'get_(?:[^_]+)_endpoint\(["\'\s]*([^"\']+)["\'],')
        self.dep_roles += map(Role.get_role, endpoint_re.findall(open(self.file_path, 'r').read()))
        include_re = re.compile(r'include_recipe\s*[\'"]([^\'"]+)[\'"]')
        self.dep_recipes += map(Recipe.get_recipe, include_re.findall(open(self.file_path, 'r').read()))
        # print "dep recipes",self.name,[r.name for r in self.dep_recipes],"roles",[r.name for r in self.dep_roles]
 
    def get_dep_roles(self):
        """Get roles that this recipe depends on"""
        dep_roles = []
        dep_roles += self.dep_roles
        for recipe in self.dep_recipes:
            dep_roles += recipe.get_dep_roles()
        return dep_roles
 
    @classmethod
    def strip_module(cls, name):
        match = cls.name_re.match(name)
        return match.group('recipe_name')
 
    @classmethod
    def get_recipe(cls, name):
        #test if full name is in recipes dict
        if name not in cls.recipes:
            #test if there is a match for recipe name only (no module::)
            for recipe_name, recipe in cls.recipes.items():
                if cls.strip_module(recipe_name) == cls.strip_module(name):
                    return recipe
            #if cls.strip_module(name) in map(cls.strip_module,cls.recipes):
            #   return cls.recipes[cls.strip_module(name)]
            #no instance found, even without a module name, so create a new instance
            else:
                cls.recipes[name] = cls(name)
        return cls.recipes[name]
 
    @classmethod
    def recipe_from_path(cls, path):
        recipe = cls.get_recipe(cls.name_from_path(path)[0])
        if not recipe.file_path:
            recipe.file_path = path
        return recipe
 
 
class Role:
    roles = {}
 
    def __init__(self, name=None, file_path=None):
        self.name = name
        self.file_path = file_path
        self.dep_recipes = []
        self.dep_roles = []
        Role.roles[self.name] = self
 
    def process_role(self):
        self.role_re = re.compile(r'role\[([^]]*)\]')
        self.recipe_re = re.compile(r'recipe\[([^]]*)\]')
        self.dep_recipes += map(Recipe.get_recipe, self.recipe_re.findall(open(self.file_path, 'r').read()))
        self.dep_roles += map(Role.get_role, self.role_re.findall(open(self.file_path, 'r').read()))
 
    def get_deps_from_recipes(self):
        deps = []
        for recipe in self.dep_recipes:
            deps += recipe.get_dep_roles()
        return deps
 
    def get_deps_from_roles(self):
        return self.dep_roles
 
    @classmethod
    def name_from_path(cls, path):
        return os.path.split(path)[1].split('.')[0]
 
    @classmethod
    def get_role(cls, name):
        if name not in Role.roles:
            Role.roles[name] = Role(name=name)
        return Role.roles[name]
 
    @classmethod
    def role_from_path(cls, path):
        role = cls.get_role(cls.name_from_path(path))
        if not role.file_path:
            role.file_path = path
        return role
 
 
def main(argv=None):
    if not argv:
        argv = sys.argv[1:]
    parser = argparse.ArgumentParser()
    parser.add_argument('path', help='Path to root of chef cookbooks repository')
    parser.add_argument('--cookbook-metadata', help='List dependencies between cookbooks from cookbook metadata.',
                        action='store_true')
    parser.add_argument('--get-endpoint', help='List dependencies between roles. '
                                               'Role A is dependent on role B if one of the recipes required by '
                                               + 'role A calls get_*_endpoint("Role B",_,_)',
                        action='store_true')
    parser.add_argument('--role-def', help='List dependencies between roles as listed in the role definitions.',
                        action='store_true')
    parser.add_argument('--remove-self-deps',help='Dont list self dependencies (eg A-->A)',action='store_true')
    args = parser.parse_args(argv)
 
    if not (args.cookbook_metadata or args.get_endpoint or args.role_def):
        parser.print_help()
        print
        print "Atleast one of --cookbook-metadata, --get-endpoint, --role-def is required."
        return 1
 
    gd = GetDeps(args.path)
    gd.process_chef_repo()
    deps = set()
 
    #Add cookbook metadata deps if requested
    if args.cookbook_metadata:
        deps.update(Cookbook.get_all_cookbook_deps())
 
    #Add get-endpoint deps if requested
    if args.get_endpoint:
        for role in Role.roles.values():
            for dep in role.get_deps_from_recipes():
                deps.add((role.name, dep.name))
 
    #Add role-deps if requested
    if args.role_def:
        for role in Role.roles.values():
            for dep in role.get_deps_from_roles():
                deps.add((role.name, dep.name))
 
    #Remove loopback connections if requested
    if args.remove_self_deps:
        del_list = []
        for dep in deps:
            if dep[0] == dep[1]:
                del_list.append(dep)
        for dep in del_list:
            deps.remove(dep)
 
    if deps:
        for dep in deps:
            print "%s,%s" % dep
    else:
        print "No deps found"
        return 1
 
 
if __name__ == "__main__":
    sys.exit(main())
