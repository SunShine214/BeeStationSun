import { useBackend } from '../backend';
import { Box, Knob, NumberInput, ProgressBar, Section } from '../components';
import { Window } from '../layouts';

export const AtmosIcafr = (props) => {
  const { act, data } = useBackend();
  const {
    reaction_energy,
    display_power,
    reaction_harvesting,
    reaction_harvesting_efficiency,
    display_parabolic_production,
    annihilation_input_rate,
    fuel_input_rate,
    containment_energy,
    max_stability,
    stability,
    parabolic_ratio,
    parabolic_hold_setting,
    parabolic_hold_gain,
  } = data;
  return (
    <Window theme="ntos" width={480} height={500}>
      <Window.Content>
        <Section title="ICAFR:" fill={1} overflow-y="scroll">
          <ProgressBar
            minValue={0}
            maxValue={max_stability}
            value={stability}
            ranges={{
              good: [0.7, Infinity],
              average: [0.4, 0.7],
              bad: [-Infinity, 0.4],
            }}
          />
          <br />
          Containment Energy
          <br />
          {containment_energy}
          <br />
          Reaction Energy
          <br />
          {reaction_energy}
          <br />
          Output Power
          <br />
          {display_power}
          <br />
          Reaction Harvesting
          <br />
          {reaction_harvesting}
          <br />
          Reaction Harvesting Efficiency
          <br />
          {reaction_harvesting_efficiency}
          <br />
          Parabolic Production
          <br />
          {display_parabolic_production}
          <br />
          Parabolic Ratio
          <br />
          {parabolic_ratio}
          <br />
          Annihilation Input
          <br />
          <NumberInput
            animated
            value={parseFloat(annihilation_input_rate)}
            width="75px"
            unit="L/s"
            minValue={0}
            maxValue={200}
            step={10}
            onChange={(value) =>
              act('change_annihilation', {
                change_annihilation: value,
              })
            }
          />
          <br />
          Fuel Input
          <br />
          <NumberInput
            animated
            value={parseFloat(fuel_input_rate)}
            width="75px"
            unit="L/s"
            minValue={0}
            maxValue={200}
            step={10}
            onChange={(value) =>
              act('change_fuel', {
                change_fuel: value,
              })
            }
          />
          <br />
          Hold Value
          <br />
          <NumberInput
            animated
            value={parseFloat(parabolic_hold_setting).toFixed(2)}
            width="75px"
            unit=""
            minValue={0}
            maxValue={200}
            step={0.1}
            onChange={(value) =>
              act('hold_value', {
                hold_value: value,
              })
            }
          />
          <br />
          Hold Gain
          <br />
          <Box>
            <Knob
              size={1.25}
              color={'yellow'}
              value={parabolic_hold_gain}
              unit=""
              minValue={0}
              maxValue={1}
              step={0.1}
              stepPixelSize={1}
              onDrag={(e, value) =>
                act('change_hold_gain', {
                  change_hold_gain: value,
                })
              }
            />
          </Box>
        </Section>
      </Window.Content>
    </Window>
  );
};
