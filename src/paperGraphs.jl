export plotHeatmaps, plotScatters
# This is mostly just yoinked from the previous papers' stuff, as those heatmaps were excellent

using Plots, StatsPlots

Plots.default(size=(1080,720))
colorscheme = :amp
textCol = "#555577"

function centerTicks(series)
    series = series
    min,max = extrema(series)
    labels = range(min,max, step=1)
    labelStep = step(labels)
    locs = range(min+(labelStep/2), step=labelStep, stop=max+(labelStep/2))
    return (locs, labels)
end

"""
For each pair of x and y, increment that space in the matrix by one.
"""
function countMatrix(xs,ys; xlims=missing, ylims=missing)
    xStart,xEnd = if (xlims !== missing) xlims else extrema(xs) end
    yStart,yEnd = if (ylims !== missing) ylims else extrema(ys) end
    counts = fill(0, yEnd - yStart + 1, xEnd - xStart + 1) # add 1 cos 1 based index
    for (x,y) in zip(xs, ys)
        val = counts[y-yStart+1,x-xStart+1]
        if val === missing
            counts[y-yStart+1,x-xStart+1] = 1
        else
            counts[y-yStart+1,x-xStart+1] += 1
        end
    end
    return (counts, xStart:xEnd, yStart:yEnd)
end


function extractAspects(aspectX,aspectY; data)
    both = data[:, [aspectX,aspectY]] |> dropmissing
    x = both[:,aspectX]
    y = both[:,aspectY]
    return (x,y)
end
# TODO: Get this kind of heatmap working
function heatmap(aspectX,aspectY; data, objFilter=missing, annotate=true, textColour=:skyblue2, kwargs...)
    if !ismissing(objFilter)
        data = data[data.objective .== objFilter, :]
    end
    x,y = extractAspects(aspectX, aspectY; data=data)
    getLimits(aspect) = missing
    counts,xNums,yNums = countMatrix(x,y, xlims=getLimits(aspectX), ylims=getLimits(aspectY))
    xOffset, yOffset = xNums[1]-1, yNums[1]-1
    anns = 
        if annotate
            [(x,y, text(coalesce(counts[y-yOffset,x-xOffset], ""), 14, textColour)) for (y,x) in Iterators.product(yNums, xNums)] |> vec
        else 
            []
        end

    Plots.heatmap(xNums,yNums,counts,
        xlabel=aspectX, ylabel=aspectY, title="$aspectX vs $aspectY", minorgrid=true, minorticks=2, 
        xticks=xNums, yticks=yNums,
        minorgridalpha=0.2, gridalpha=0.0, 
        minorgridstyle=:solid, aspect_ratio=:none, tick_direction=:out,annotations=anns; kwargs...)
end

function plotScatter(data, (x,y); kwargs...)
    scatter(data[!,x], data[!,y], xlabel=x, ylabel=y, legend=false; kwargs...)
end
function plotScatters(data, relationships; kwargs...)
    subplots = [plotScatter(data, rel; kwargs...) for rel in relationships]
    plot(subplots..., layout=length(relationships))
end


function plotHeatmaps(byAspect)
    
    # heatmap(:Diff, :Certainty, data=withDiff, aspect_ratio=:equal, 
    #     title="",
    #     xlabel="Balance of Power: Player Power - Opponent Power", 
    #     ylabel="Certainty of Outcome",
    #     c=colorscheme, textColour=textCol)
    # savefig("./pics/paper/Balance of Power")

    # heatmap(:Certainty, :Tension, title="", 
    #     xlabel="Certainty of Outcome",
    #     c=colorscheme, textColour=textCol)
    # savefig("./pics/paper/certaintyVsTension")

    heatmap(:Investment, :Tension, data=byAspect, annotate=true, title="", 
        xlabel="Player Investment",
        c=colorscheme, textColour=textCol)
    savefig("./pics/paper/investmentVsTension")

    heatmap(:EnemyPower, :OwnPower, data=byAspect, title="", 
    xlabel="Opponent Power", ylabel="Player Power", c=colorscheme, textColour=textCol)
    savefig("./pics/paper/OpponentVsPlayer")

    heatmap(:OwnPower, :Tension, data=byAspect, title="", 
    xlabel="Player Power", ylabel="Tension", c=colorscheme, textColour=textCol)
    savefig("./pics/paper/PlayerVsTension")

    heatmap(:EnemyPower, :Tension, data=byAspect, title="", 
    xlabel="Opponent Power", ylabel="Tension", c=colorscheme, textColour=textCol)
    savefig("./pics/paper/OpponentVsTension")
end

function participantObjectivesSpread(observations)
    all = [:Importance, :Want, :Need, :Investment, :OwnPower, :EnemyPower, :Tension, :PowerDifference]
    gdf = groupby(observations, :outlier)
    for x in all
        regular, outliers = gdf[(;outlier=false)], gdf[(;outlier=true)]
        violin(regular.objective, regular[:,x]) 
        scatter!(outliers.objective, outliers[:,x], hover=outliers.ParticipantID)
        plot!(title=String(x)) |> display
    end

    # Weird observations this shows:
    # 3IR felt the enemies had NO power to stop, though because they didn't ever find the ritual, they felt they had no power to destroy the ritual
    # R_25ATgZ4RVxbTMkg was the only one who felt completely overwhelmed with the ritual - enemy had complete power to stop them, they had none
end