local Translations = {
    notifications = {
        success = {
            repaired = 'Vehicle repaired!',
            paid = 'You paid $%{amount} from your bank account'
        },
        error = {
            money = 'You don\'t have enough money!',
            alreadyInstalled = 'You already have this mod installed'
        },
        props = {
            installTitle = 'Customs'
        }
    },
    dragCam = {
        zoomIn = 'Increase zoom',
        zoomOut = 'Decrease zoom'
    },
    textUI = {
        tune =  'Press [E] to tune your car'
    },
    menus = {
        main = {
            title = 'Popcorn Customs',
            repair = 'Repair',
            performance = 'Performance',
            parts = 'Cosmetics - Parts',
            colors = 'Cosmetics - Colors',
            extras = 'Extras'
        },
        colors = {
            primary = 'Paint primary',
            secondary = 'Paint secondary',
            neon = 'Neon',
            cosmetics_colors = 'Cosmetics - Colors'
        },
        neon = {
            title = 'Neon',
            neon = 'Neon %{label}, %{state}',
            color = 'Neon color',
            installed = '%{neon} neon installed'
        },
        paint = {
            title = 'Cosmetics - Colors',
            primary = 'Primary paint',
            secondary = 'Secondary paint'
        },
        parts = {
            title = 'Cosmetics - Parts',
            wheels = 'Wheels',
        },
        performance = {
            title = 'Performance',
            turbo = 'Turbo',
        },
        wheels = {
            title = 'Wheels',
            bikeRear = 'Bike rear wheel',
            installed = '%{category} %{wheel} installed'
        },
        options = {
            interior = 'Interior',
            livery = 'Livery',
            pearlescent = 'Pearlescent',
            plateIndex = {
                title = 'Plate Index',
                installed = '%{plate} plate installed'
            },
            tyreSmoke = 'Tyre smoke',
            wheelColor = 'Wheel color',
            windowTint = {
                title = 'Window Tint',
                installed = '%{window} windows installed'
            },
            xenon = {
                title = 'Xenon',
                installed = '%{color} xenon installed'
            }
        },
        general = {
            stock = 'Stock',
            enabled = 'Enabled',
            disabled = 'Disabled',
            installed = '%{element} installed',
            applied = '%{element} applied'
        },
    },
    general = {
        payReason = 'Customs',
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true,
    fallbackLang = Lang,
})