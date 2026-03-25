# Add to ~/.config/fish/config.fish
function ask
    sgpt $argv
end

function shell  
    sgpt --shell $argv
end
