'use strict';

const fs = require('fs');
const preferencePath = '/Users/fresh/.hyper.js'

if(fs.existsSync(preferencePath)){
    // make a backup
    fs.copyFile(preferencePath, preferencePath + '.bak', (e) => { if (e) throw e;});
    const rawHyperPreferences = fs.readFileSync(preferencePath, 'utf8');
    const custumPluginSection = `// for advanced config flags please refer to https://hyper.is/#cfg 
    hypercwd: {
        initialWorkingDirectory: '~/Development'
    },
    hyperTabs: {
        tabIonsColored: true,
        activityColor: 'cyan',
        closeAlign: 'right'
    },
    hyperTabsMove: {
        moveLeft: 'command+[',
        moveRight: 'command+]'
    }`
    const settingsWithCustomPlugins = rawHyperPreferences.replace("// for advanced config flags please refer to https://hyper.is/#cfg", custumPluginSection);
    const addPlugins = ['hyper-dracula', 'hyper-search', 'hypercwd', 'hyper-alt-click', 'hyper-pane']
    const newSettings = settingsWithCustomPlugins.replace(/plugins: \[\]/, "plugins: " + JSON.stringify(addPlugins) );
    fs.writeFile(preferencePath, newSettings, (e) => {if (e) throw e;});
} else {
    console.log('Hyper preferences do not exist at: ', preferencePath)
}

