function generate_toy_data(rng::AbstractRNG)
    x = range(0, 10; length=5)
    ys = rand(rng, GP(SEKernel())(x, 1e-6), 3)
    y1 = ys[:, 1]
    y2 = ys[:, 2]
    y3 = ys[:, 3]
    indices = randcycle(rng, 5)
    x_train = zeros(3)
    y_1_train = zeros(3)
    y_2_train = zeros(3)
    y_3_train = zeros(3)
    x_test = zeros(2)
    y_1_test = zeros(2)
    y_2_test = zeros(2)
    y_3_test = zeros(2)
    for (i, val) in enumerate(indices)
        if i <= 3
            x_train[i] = x[val]
            y_1_train[i] = y1[val]
            y_2_train[i] = y2[val]
            y_3_train[i] = y3[val]
        else
            x_test[i - 3] = x[val]
            y_1_test[i - 3] = y1[val]
            y_2_test[i - 3] = y2[val]
            y_3_test[i - 3] = y3[val]
        end
    end
    x_train = MOInputIsotopicByOutputs(x_train, 3)
    x_test = MOInputIsotopicByOutputs(x_test, 3)
    y_train = vcat(y_1_train, y_2_train, y_3_train)
    y_test = vcat(y_1_test, y_2_test, y_3_test)

    return x_train, x_test, y_train, y_test
end